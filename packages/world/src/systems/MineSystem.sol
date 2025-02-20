// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord, VoxelCoordLib } from "../VoxelCoord.sol";

import { MinedOrePosition } from "../codegen/tables/MinedOrePosition.sol";
import { MinedOreCount } from "../codegen/tables/MinedOreCount.sol";
import { TotalMinedOreCount } from "../codegen/tables/TotalMinedOreCount.sol";
import { OreCommitment } from "../codegen/tables/OreCommitment.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Chip } from "../codegen/tables/Chip.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Mass } from "../codegen/tables/Mass.sol";
import { LocalEnergyPool } from "../codegen/tables/LocalEnergyPool.sol";
import { DisplayContent, DisplayContentData } from "../codegen/tables/DisplayContent.sol";
import { ActionType, DisplayContentType } from "../codegen/common.sol";

import { ObjectTypeId, AirObjectID, WaterObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { AnyOreObjectID, CoalOreObjectID, SilverOreObjectID, GoldOreObjectID, DiamondOreObjectID, NeptuniumOreObjectID } from "../ObjectTypeIds.sol";
import { inWorldBorder, getUniqueEntity } from "../Utils.sol";
import { addToInventoryCount, useEquipped } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { updateMachineEnergyLevel, energyToMass, transferEnergyFromPlayerToPool } from "../utils/EnergyUtils.sol";
import { notify, MineNotifData } from "../utils/NotifUtils.sol";
import { MoveLib } from "./libraries/MoveLib.sol";
import { ForceFieldLib } from "./libraries/ForceFieldLib.sol";
import { getObjectTypeSchema } from "../utils/ObjectTypeUtils.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";
import { EntityId } from "../EntityId.sol";
import { PLAYER_MINE_ENERGY_COST } from "../Constants.sol";
import { ChunkCoord } from "../Types.sol";
import { COMMIT_EXPIRY_BLOCKS, MAX_COAL, MAX_SILVER, MAX_GOLD, MAX_DIAMOND, MAX_NEPTUNIUM } from "../Constants.sol";

library MineLib {
  function mineRandomOre(VoxelCoord memory coord) public returns (ObjectTypeId) {
    ChunkCoord memory chunkCoord = coord.toChunkCoord();
    uint256 blockNum = OreCommitment._get(chunkCoord.x, chunkCoord.y, chunkCoord.z);
    require(blockNum > block.number - COMMIT_EXPIRY_BLOCKS, "Ore commitment expired");
    uint256 rand = uint256(blockhash(blockNum));

    // Set total mined ore and add position
    // We do this here to avoid stack too deep issues
    uint256 totalMinedOre = TotalMinedOreCount._get();
    MinedOrePosition._set(totalMinedOre, coord.x, coord.y, coord.z);
    TotalMinedOreCount._set(totalMinedOre + 1);

    // TODO: can optimize by not storing these in memory and returning the type depending on for loop index
    ObjectTypeId[5] memory ores = [
      CoalOreObjectID,
      SilverOreObjectID,
      GoldOreObjectID,
      DiamondOreObjectID,
      NeptuniumOreObjectID
    ];

    uint256[5] memory mined = [
      MinedOreCount._get(CoalOreObjectID),
      MinedOreCount._get(SilverOreObjectID),
      MinedOreCount._get(GoldOreObjectID),
      MinedOreCount._get(DiamondOreObjectID),
      MinedOreCount._get(NeptuniumOreObjectID)
    ];

    uint256[5] memory max = [MAX_COAL, MAX_SILVER, MAX_GOLD, MAX_DIAMOND, MAX_NEPTUNIUM];

    // Calculate remaining amounts for each ore and total remaining
    uint256[5] memory remaining;
    uint256 totalRemaining = 0;
    for (uint256 i = 0; i < remaining.length; i++) {
      remaining[i] = max[i] - mined[i];
      totalRemaining += remaining[i];
    }

    uint256 oreIndex = 0;
    {
      // Scale random number to total remaining
      // TODO: use muldiv from solady or OZ to prevent overflow
      uint256 scaledRand = (rand * totalRemaining) / type(uint256).max;

      uint256 acc;
      for (; oreIndex < remaining.length - 1; oreIndex++) {
        acc += remaining[oreIndex];
        if (scaledRand < acc) break;
      }
    }

    ObjectTypeId ore = ores[oreIndex];

    uint256 remainingOre = remaining[oreIndex];
    require(remainingOre > 0, "No ores available to mine");
    MinedOreCount._set(ore, mined[oreIndex] + 1);

    return ore;
  }

  function processMassReduction(EntityId playerEntityId, EntityId minedEntityId) public returns (uint128) {
    (uint128 toolMassReduction, ) = useEquipped(playerEntityId);
    uint128 totalMassReduction = energyToMass(PLAYER_MINE_ENERGY_COST) + toolMassReduction;
    uint128 massLeft = Mass._getMass(minedEntityId);
    return massLeft <= totalMassReduction ? 0 : massLeft - totalMassReduction;
  }
}

contract MineSystem is System {
  using VoxelCoordLib for *;

  function _getSchemaCoords(
    ObjectTypeId objectTypeId,
    VoxelCoord memory baseCoord
  ) internal pure returns (VoxelCoord[] memory) {
    VoxelCoord[] memory coords = getObjectTypeSchema(objectTypeId);

    for (uint256 i = 0; i < coords.length; i++) {
      coords[i] = VoxelCoord(baseCoord.x + coords[i].x, baseCoord.y + coords[i].y, baseCoord.z + coords[i].z);
    }

    return coords;
  }

  // TODO: if there's a player on top of another one, they won't be updated
  function _removeBlock(EntityId entityId, VoxelCoord memory coord) internal {
    ObjectType._set(entityId, AirObjectID);

    VoxelCoord memory aboveCoord = VoxelCoord(coord.x, coord.y + 1, coord.z);
    EntityId aboveEntityId = aboveCoord.getPlayer();
    if (aboveEntityId.exists()) {
      MoveLib.runGravity(aboveEntityId, aboveCoord);
    }
  }

  function mineWithExtraData(VoxelCoord memory coord, bytes memory extraData) public payable {
    require(inWorldBorder(coord), "Cannot mine outside the world border");

    (EntityId playerEntityId, VoxelCoord memory playerCoord, EnergyData memory playerEnergyData) = requireValidPlayer(
      _msgSender()
    );
    requireInPlayerInfluence(playerCoord, coord);

    (EntityId entityId, ObjectTypeId mineObjectTypeId) = coord.getOrCreateEntity();
    require(mineObjectTypeId.isMineable(), "Object is not mineable");

    transferEnergyFromPlayerToPool(playerEntityId, playerCoord, playerEnergyData, PLAYER_MINE_ENERGY_COST);

    EntityId baseEntityId = entityId.baseEntityId();

    if (mineObjectTypeId == AnyOreObjectID) {
      mineObjectTypeId = MineLib.mineRandomOre(coord);
    } else {
      require(baseEntityId.getChipAddress() == address(0), "Cannot mine a chipped block");
      require(updateMachineEnergyLevel(baseEntityId).energy == 0, "Cannot mine a machine that has energy");
    }

    uint128 finalMass = MineLib.processMassReduction(playerEntityId, baseEntityId);

    if (finalMass == 0) {
      Mass._deleteRecord(baseEntityId);

      if (DisplayContent._getContentType(baseEntityId) != DisplayContentType.None) {
        DisplayContent._deleteRecord(baseEntityId);
      }

      addToInventoryCount(playerEntityId, PlayerObjectID, mineObjectTypeId, 1);

      _removeBlock(baseEntityId, coord);

      VoxelCoord[] memory schemaCoords = _getSchemaCoords(mineObjectTypeId, coord);

      for (uint256 i = 0; i < schemaCoords.length; i++) {
        VoxelCoord memory relativeCoord = schemaCoords[i];
        (EntityId relativeEntityId, ) = relativeCoord.getOrCreateEntity();
        BaseEntity._deleteRecord(relativeEntityId);

        _removeBlock(relativeEntityId, relativeCoord);
      }
    } else {
      Mass._setMass(baseEntityId, finalMass);
    }

    notify(
      playerEntityId,
      MineNotifData({ mineEntityId: baseEntityId, mineCoord: coord, mineObjectTypeId: mineObjectTypeId })
    );

    ForceFieldLib.requireMineAllowed(playerEntityId, baseEntityId, mineObjectTypeId, coord, extraData);
  }

  function mine(VoxelCoord memory coord) public payable {
    mineWithExtraData(coord, new bytes(0));
  }
}
