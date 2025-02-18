// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { VoxelCoord } from "../VoxelCoord.sol";
import { Mass } from "../codegen/tables/Mass.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { ObjectTypeSchema, ObjectTypeSchemaData } from "../codegen/tables/ObjectTypeSchema.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { InventoryObjects } from "../codegen/tables/InventoryObjects.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { ForceFieldMetadata } from "../codegen/tables/ForceFieldMetadata.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { ActionType } from "../codegen/common.sol";

import { ObjectTypeId, AirObjectID, WaterObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { inWorldBorder, getUniqueEntity } from "../Utils.sol";
import { removeFromInventoryCount, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";

import { PLAYER_BUILD_ENERGY_COST } from "../Constants.sol";
import { transferEnergyFromPlayerToPool } from "../utils/EnergyUtils.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";
import { ForceFieldLib } from "./libraries/ForceFieldLib.sol";
import { notify, BuildNotifData, MoveNotifData } from "../utils/NotifUtils.sol";

import { EntityId } from "../EntityId.sol";

contract BuildSystem is System {
  function buildObjectAtCoord(ObjectTypeId objectTypeId, VoxelCoord memory coord) internal returns (EntityId) {
    require(inWorldBorder(coord), "Cannot build outside the world border");
    EntityId entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    if (!entityId.exists()) {
      ObjectTypeId terrainObjectTypeId = ObjectTypeId.wrap(TerrainLib._getBlockType(coord));
      require(terrainObjectTypeId == AirObjectID, "Cannot build on a non-air block");

      entityId = getUniqueEntity();
      Position._set(entityId, coord.x, coord.y, coord.z);
      ReversePosition._set(coord.x, coord.y, coord.z, entityId);
    } else {
      require(ObjectType._get(entityId) == AirObjectID, "Cannot build on a non-air block");
      require(InventoryObjects._lengthObjectTypeIds(entityId) == 0, "Cannot build where there are dropped objects");
    }

    ObjectType._set(entityId, objectTypeId);

    return entityId;
  }

  function buildWithExtraData(
    ObjectTypeId objectTypeId,
    VoxelCoord memory coord,
    bytes memory extraData
  ) public payable returns (EntityId) {
    require(objectTypeId.isBlock(), "Cannot build non-block object");
    (EntityId playerEntityId, VoxelCoord memory playerCoord, EnergyData memory playerEnergyData) = requireValidPlayer(
      _msgSender()
    );
    requireInPlayerInfluence(playerCoord, coord);

    EntityId baseEntityId = buildObjectAtCoord(objectTypeId, coord);
    uint256 numRelativePositions = ObjectTypeSchema._lengthRelativePositionsX(objectTypeId);
    VoxelCoord[] memory coords = new VoxelCoord[](numRelativePositions + 1);
    coords[0] = coord;
    if (numRelativePositions > 0) {
      ObjectTypeSchemaData memory schemaData = ObjectTypeSchema._get(objectTypeId);
      for (uint256 i = 0; i < numRelativePositions; i++) {
        VoxelCoord memory relativeCoord = VoxelCoord(
          coord.x + schemaData.relativePositionsX[i],
          coord.y + schemaData.relativePositionsY[i],
          coord.z + schemaData.relativePositionsZ[i]
        );
        coords[i + 1] = relativeCoord;
        EntityId entityId = buildObjectAtCoord(objectTypeId, relativeCoord);
        BaseEntity._set(entityId, baseEntityId);
      }
    }
    uint32 mass = ObjectTypeMetadata._getMass(objectTypeId);
    Mass._setMass(baseEntityId, mass);
    VoxelCoord memory shardCoord = coord.toForceFieldShardCoord();
    ForceFieldMetadata._setTotalMassInside(
      shardCoord.x,
      shardCoord.y,
      shardCoord.z,
      ForceFieldMetadata._getTotalMassInside(shardCoord.x, shardCoord.y, shardCoord.z) + mass
    );
    transferEnergyFromPlayerToPool(playerEntityId, playerCoord, playerEnergyData, PLAYER_BUILD_ENERGY_COST);

    removeFromInventoryCount(playerEntityId, objectTypeId, 1);

    notify(
      playerEntityId,
      BuildNotifData({ buildEntityId: baseEntityId, buildCoord: coord, buildObjectTypeId: objectTypeId })
    );

    // Note: we call this after the build state has been updated, to prevent re-entrancy attacks
    ForceFieldLib.requireBuildsAllowed(playerEntityId, baseEntityId, objectTypeId, coords, extraData);

    return baseEntityId;
  }

  function jumpBuildWithExtraData(ObjectTypeId objectTypeId, bytes memory extraData) public payable {
    (EntityId playerEntityId, VoxelCoord memory playerCoord, ) = requireValidPlayer(_msgSender());
    VoxelCoord memory jumpCoord = VoxelCoord(playerCoord.x, playerCoord.y + 1, playerCoord.z);
    require(inWorldBorder(jumpCoord), "Cannot jump outside world border");
    EntityId newEntityId = ReversePosition._get(jumpCoord.x, jumpCoord.y, jumpCoord.z);
    if (!newEntityId.exists()) {
      ObjectTypeId terrainObjectTypeId = ObjectTypeId.wrap(TerrainLib._getBlockType(jumpCoord));
      require(terrainObjectTypeId == AirObjectID, "Cannot jump on a non-air block");
      newEntityId = getUniqueEntity();
      ObjectType._set(newEntityId, AirObjectID);
    } else {
      require(ObjectType._get(newEntityId) == AirObjectID, "Cannot jump on a non-air block");
      transferAllInventoryEntities(newEntityId, playerEntityId, PlayerObjectID);
    }

    // Swap entity ids
    ReversePosition._set(playerCoord.x, playerCoord.y, playerCoord.z, newEntityId);
    Position._set(newEntityId, playerCoord.x, playerCoord.y, playerCoord.z);

    Position._set(playerEntityId, jumpCoord.x, jumpCoord.y, jumpCoord.z);
    ReversePosition._set(jumpCoord.x, jumpCoord.y, jumpCoord.z, playerEntityId);

    // TODO: apply jump cost
    VoxelCoord[] memory moveCoords = new VoxelCoord[](1);
    moveCoords[0] = jumpCoord;
    notify(playerEntityId, MoveNotifData({ moveCoords: moveCoords }));

    buildWithExtraData(objectTypeId, playerCoord, extraData);
  }

  function jumpBuild(ObjectTypeId objectTypeId) public payable {
    jumpBuildWithExtraData(objectTypeId, new bytes(0));
  }

  function build(ObjectTypeId objectTypeId, VoxelCoord memory coord) public payable returns (EntityId) {
    return buildWithExtraData(objectTypeId, coord, new bytes(0));
  }
}
