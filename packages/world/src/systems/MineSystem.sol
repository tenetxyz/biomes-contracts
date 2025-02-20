// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord, VoxelCoordLib } from "../VoxelCoord.sol";

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

import { ObjectTypeId, AirObjectID, WaterObjectID, PlayerObjectID, AnyOreObjectID } from "../ObjectTypeIds.sol";
import { inWorldBorder, getUniqueEntity } from "../Utils.sol";
import { addToInventoryCount, useEquipped } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { updateMachineEnergyLevel, energyToMass, transferEnergyFromPlayerToPool } from "../utils/EnergyUtils.sol";
import { notify, MineNotifData } from "../utils/NotifUtils.sol";
import { MoveLib } from "./libraries/MoveLib.sol";
import { ForceFieldLib } from "./libraries/ForceFieldLib.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";
import { EntityId } from "../EntityId.sol";
import { PLAYER_MINE_ENERGY_COST } from "../Constants.sol";

contract MineSystem is System {
  using VoxelCoordLib for *;

  function mineObjectAtCoord(VoxelCoord memory coord) internal returns (EntityId, ObjectTypeId) {
    require(inWorldBorder(coord), "Cannot mine outside the world border");

    (EntityId entityId, ObjectTypeId mineObjectTypeId) = coord.getOrCreateEntity();
    require(mineObjectTypeId.isBlock(), "Cannot mine non-block object");
    require(mineObjectTypeId != AnyOreObjectID, "Ore must be computed before it can be mined");
    require(mineObjectTypeId != AirObjectID, "Cannot mine air");
    require(mineObjectTypeId != WaterObjectID, "Cannot mine water");

    require(entityId.getChipAddress() == address(0), "Cannot mine a chipped block");
    EnergyData memory machineData = updateMachineEnergyLevel(entityId);
    require(machineData.energy == 0, "Cannot mine a machine that has energy");

    return (entityId, mineObjectTypeId);
  }

  function mineWithExtraData(VoxelCoord memory coord, bytes memory extraData) public payable {
    (EntityId playerEntityId, VoxelCoord memory playerCoord, EnergyData memory playerEnergyData) = requireValidPlayer(
      _msgSender()
    );
    requireInPlayerInfluence(playerCoord, coord);

    (EntityId baseEntityId, ObjectTypeId mineObjectTypeId) = mineObjectAtCoord(coord);
    require(!BaseEntity._get(baseEntityId).exists(), "Invalid mine coord, must mine the base coord");

    bool isFullyMined;
    {
      (uint128 toolMassReduction, ) = useEquipped(playerEntityId);
      uint128 totalMassReduction = energyToMass(PLAYER_MINE_ENERGY_COST) + toolMassReduction;
      uint128 massLeft = Mass._getMass(baseEntityId);
      transferEnergyFromPlayerToPool(playerEntityId, playerCoord, playerEnergyData, PLAYER_MINE_ENERGY_COST);
      isFullyMined = massLeft <= totalMassReduction;
      if (!isFullyMined) {
        Mass._setMass(baseEntityId, massLeft - totalMassReduction);
      }
    }

    VoxelCoord[] memory relativePositions = mineObjectTypeId.getObjectTypeSchema();
    VoxelCoord[] memory coords = new VoxelCoord[](relativePositions.length + 1);
    coords[0] = coord;

    for (uint256 i = 0; i < relativePositions.length; i++) {
      VoxelCoord memory relativeCoord = VoxelCoord(
        coord.x + relativePositions[i].x,
        coord.y + relativePositions[i].y,
        coord.z + relativePositions[i].z
      );
      coords[i + 1] = relativeCoord;

      if (isFullyMined) {
        (EntityId relativeEntityId, ) = mineObjectAtCoord(relativeCoord);
        BaseEntity._deleteRecord(relativeEntityId);
        ObjectType._set(relativeEntityId, AirObjectID);
      }
    }

    if (isFullyMined) {
      Mass._deleteRecord(baseEntityId);
      if (DisplayContent._getContentType(baseEntityId) != DisplayContentType.None) {
        DisplayContent._deleteRecord(baseEntityId);
      }
      ObjectType._set(baseEntityId, AirObjectID);

      addToInventoryCount(playerEntityId, PlayerObjectID, mineObjectTypeId, 1);

      for (uint256 i = 0; i < coords.length; i++) {
        VoxelCoord memory aboveCoord = VoxelCoord(coords[i].x, coords[i].y + 1, coords[i].z);
        EntityId aboveEntityId = aboveCoord.getPlayer();
        if (aboveEntityId.exists() && aboveEntityId.isBaseEntity()) {
          MoveLib.runGravity(aboveEntityId, aboveCoord);
        }
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
