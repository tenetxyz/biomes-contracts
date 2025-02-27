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
import { Orientation } from "../codegen/tables/Orientation.sol";
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
import { EntityId } from "../EntityId.sol";
import { PLAYER_MINE_ENERGY_COST } from "../Constants.sol";
import { ChunkCoord } from "../Types.sol";
import { mulDiv } from "../utils/MathUtils.sol";
import { CHUNK_COMMIT_EXPIRY_BLOCKS, MAX_COAL, MAX_SILVER, MAX_GOLD, MAX_DIAMOND, MAX_NEPTUNIUM } from "../Constants.sol";

library MineLib {
  function mineRandomOre(VoxelCoord memory coord) public returns (ObjectTypeId) {
    ChunkCoord memory chunkCoord = coord.toChunkCoord();
    uint256 commitment = OreCommitment._get(chunkCoord.x, chunkCoord.y, chunkCoord.z);
    // We can't get blockhash of current block
    require(block.number > commitment, "Not within commitment blocks");
    require(block.number <= commitment + CHUNK_COMMIT_EXPIRY_BLOCKS, "Ore commitment expired");
    uint256 rand = uint256(keccak256(abi.encode(blockhash(commitment), coord)));

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

    uint256[5] memory max = [MAX_COAL, MAX_SILVER, MAX_GOLD, MAX_DIAMOND, MAX_NEPTUNIUM];

    // For y > -50: More common ores (coal, silver)
    // For y <= -50: More rare ores (gold, diamond, neptunium)
    // uint256[5] memory depthMultiplier;
    // if (coord.y > -50) {
    //   depthMultiplier = [uint256(4), 3, 1, 1, 1];
    // } else {
    //   depthMultiplier = [uint256(1), 1, 3, 4, 4];
    // }

    // Calculate remaining amounts for each ore and total remaining
    uint256[5] memory remaining;
    uint256 totalRemaining = 0;
    for (uint256 i = 0; i < remaining.length; i++) {
      // remaining[i] = (max[i] - mined[i]) * depthMultiplier[i];
      remaining[i] = max[i] - MinedOreCount._get(ores[i]);
      totalRemaining += remaining[i];
    }

    require(totalRemaining > 0, "No ores available to mine");

    uint256 oreIndex = 0;
    {
      // Scale random number to total remaining
      uint256 scaledRand = mulDiv(rand, totalRemaining, type(uint256).max);

      uint256 acc;
      for (; oreIndex < remaining.length - 1; oreIndex++) {
        acc += remaining[oreIndex];
        if (scaledRand < acc) break;
      }
    }

    ObjectTypeId ore = ores[oreIndex];
    MinedOreCount._set(ore, max[oreIndex] - remaining[oreIndex] + 1);

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

  function _removeBlock(EntityId entityId, VoxelCoord memory coord) internal {
    ObjectType._set(entityId, AirObjectID);

    VoxelCoord memory aboveCoord = VoxelCoord(coord.x, coord.y + 1, coord.z);
    EntityId aboveEntityId = aboveCoord.getPlayer();
    // Note: currently it is not possible for the above player to not be the base entity,
    // but if we add other types of movable entities we should check that it is a base entity
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
    VoxelCoord memory baseCoord = Position._get(baseEntityId).toVoxelCoord();

    // Chip needs to be detached first
    require(baseEntityId.getChipAddress() == address(0), "Cannot mine a chipped block");
    require(updateMachineEnergyLevel(baseEntityId).energy == 0, "Cannot mine a machine that has energy");

    // First coord will be the base coord, the rest is relative schema coords
    VoxelCoord[] memory coords = baseCoord.getRelativeCoords(mineObjectTypeId, Orientation._get(baseEntityId));

    {
      uint128 finalMass = MineLib.processMassReduction(playerEntityId, baseEntityId);
      if (finalMass == 0) {
        if (mineObjectTypeId == AnyOreObjectID) {
          mineObjectTypeId = MineLib.mineRandomOre(coord);
        }
        Mass._deleteRecord(baseEntityId);

        if (DisplayContent._getContentType(baseEntityId) != DisplayContentType.None) {
          DisplayContent._deleteRecord(baseEntityId);
        }

        // If detaching from a bed with a sleeping player, kill the player
        if (mineObjectTypeId == BedObjectID) {
          EntityId sleepingPlayerId = BedPlayer._getPlayerEntityId(baseEntityId);
          if (sleepingPlayerId.exists()) {
            killPlayer(sleepingPlayerId);
          }
        }

        addToInventoryCount(playerEntityId, PlayerObjectID, mineObjectTypeId, 1);

        _removeBlock(baseEntityId, baseCoord);

        // Only iterate through relative schema coords
        for (uint256 i = 1; i < coords.length; i++) {
          VoxelCoord memory relativeCoord = coords[i];
          (EntityId relativeEntityId, ) = relativeCoord.getOrCreateEntity();
          BaseEntity._deleteRecord(relativeEntityId);

          _removeBlock(relativeEntityId, relativeCoord);
        }
      } else {
        Mass._setMass(baseEntityId, finalMass);
      }
    }

    notify(
      playerEntityId,
      MineNotifData({ mineEntityId: baseEntityId, mineCoord: coord, mineObjectTypeId: mineObjectTypeId })
    );

    ForceFieldLib.requireMinesAllowed(playerEntityId, baseEntityId, mineObjectTypeId, coords, extraData);
  }

  function mine(VoxelCoord memory coord) public payable {
    mineWithExtraData(coord, new bytes(0));
  }
}
