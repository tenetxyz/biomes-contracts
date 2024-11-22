// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { VoxelCoord, Rotation } from "@biomesaw/utils/src/Types.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { callInternalSystem } from "@biomesaw/utils/src/CallUtils.sol";
import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { ObjectTypeSchema, ObjectTypeSchemaData } from "../codegen/tables/ObjectTypeSchema.sol";
import { Position } from "../codegen/tables/Position.sol";
import { Orientation, OrientationData } from "../codegen/tables/Orientation.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { InventoryObjects } from "../codegen/tables/InventoryObjects.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { ActionType } from "../codegen/common.sol";

import { MAX_PLAYER_INFLUENCE_HALF_WIDTH } from "../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { inSpawnArea, inWorldBorder, getTerrainObjectTypeId, getUniqueEntity, callMintXP } from "../Utils.sol";
import { removeFromInventoryCount, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { getRelativeCoord, orientationToRotation } from "../utils/OrientationUtils.sol";

import { IForceFieldSystem } from "../codegen/world/IForceFieldSystem.sol";

contract OrientationSystem is System {
  function buildObjectAtCoord(uint8 objectTypeId, VoxelCoord memory coord) internal returns (bytes32) {
    require(inWorldBorder(coord), "BuildSystem: cannot build outside world border");
    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    if (entityId == bytes32(0)) {
      // Check terrain block type
      uint8 terrainObjectTypeId = getTerrainObjectTypeId(coord);
      require(terrainObjectTypeId != WaterObjectID, "BuildSystem: cannot build on water block");
      require(terrainObjectTypeId == AirObjectID, "BuildSystem: cannot build on terrain non-air block");

      entityId = getUniqueEntity();
      Position._set(entityId, coord.x, coord.y, coord.z);
      ReversePosition._set(coord.x, coord.y, coord.z, entityId);
    } else {
      require(getTerrainObjectTypeId(coord) != WaterObjectID, "BuildSystem: cannot build on water block");
      require(ObjectType._get(entityId) == AirObjectID, "BuildSystem: cannot build on non-air block");
      require(
        InventoryObjects._lengthObjectTypeIds(entityId) == 0,
        "BuildSystem: Cannot build where there are dropped objects"
      );
    }

    ObjectType._set(entityId, objectTypeId);
    return entityId;
  }

  function buildWithOrientationWithExtraData(
    uint8 objectTypeId,
    VoxelCoord memory coord,
    OrientationData memory orientation,
    bytes memory extraData
  ) public payable returns (bytes32) {
    uint256 initialGas = gasleft();

    require(ObjectTypeMetadata._getIsBlock(objectTypeId), "BuildSystem: object type is not a block");
    bytes32 playerEntityId;
    {
      VoxelCoord memory playerCoord;
      (playerEntityId, playerCoord) = requireValidPlayer(_msgSender());
      requireInPlayerInfluence(playerCoord, coord);
    }

    bytes32 baseEntityId = buildObjectAtCoord(objectTypeId, coord);
    if (orientation.pitch != 0 || orientation.yaw != 0) {
      Orientation._set(baseEntityId, orientation);
    }

    uint256 numRelativePositions = ObjectTypeSchema._lengthRelativePositionsX(objectTypeId);
    VoxelCoord[] memory coords = new VoxelCoord[](numRelativePositions + 1);
    coords[0] = coord;
    if (numRelativePositions > 0) {
      Rotation rotation = orientationToRotation(orientation);
      ObjectTypeSchemaData memory schemaData = ObjectTypeSchema._get(objectTypeId);
      for (uint256 i = 0; i < numRelativePositions; i++) {
        VoxelCoord memory relativeCoord = getRelativeCoord(
          coord,
          rotation,
          VoxelCoord(
            schemaData.relativePositionsX[i],
            schemaData.relativePositionsY[i],
            schemaData.relativePositionsZ[i]
          )
        );
        coords[i + 1] = relativeCoord;
        bytes32 entityId = buildObjectAtCoord(objectTypeId, relativeCoord);
        BaseEntity._set(entityId, baseEntityId);
      }
    }

    removeFromInventoryCount(playerEntityId, objectTypeId, 1);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Build,
        entityId: baseEntityId,
        objectTypeId: objectTypeId,
        coordX: coord.x,
        coordY: coord.y,
        coordZ: coord.z,
        amount: 1
      })
    );

    callMintXP(playerEntityId, initialGas, 1);

    // Note: we call this after the build state has been updated, to prevent re-entrancy attacks
    callInternalSystem(
      abi.encodeCall(
        IForceFieldSystem.requireBuildsAllowed,
        (playerEntityId, baseEntityId, objectTypeId, coords, extraData)
      )
    );

    return baseEntityId;
  }

  function buildWithOrientation(
    uint8 objectTypeId,
    VoxelCoord memory coord,
    OrientationData memory orientation
  ) public payable returns (bytes32) {
    return buildWithOrientationWithExtraData(objectTypeId, coord, orientation, new bytes(0));
  }
}
