// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { callInternalSystem } from "@biomesaw/utils/src/CallUtils.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { ObjectTypeSchema, ObjectTypeSchemaData } from "../codegen/tables/ObjectTypeSchema.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { InventoryObjects } from "../codegen/tables/InventoryObjects.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ObjectCategory, ActionType } from "../codegen/common.sol";

import { MAX_PLAYER_INFLUENCE_HALF_WIDTH } from "../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { inSpawnArea, inWorldBorder, getTerrainObjectTypeId, getUniqueEntity } from "../Utils.sol";
import { removeFromInventoryCount, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";

import { IForceFieldSystem } from "../codegen/world/IForceFieldSystem.sol";

contract BuildSystem is System {
  function buildObjectAtCoord(uint8 objectTypeId, VoxelCoord memory coord) internal returns (bytes32) {
    require(inWorldBorder(coord), "Cannot build outside the world border");
    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    require(entityId != bytes32(0), "Cannot build on an unrevealed block");
    require(ObjectType._get(entityId) == AirObjectID, "Cannot build on a non-air block");
    require(InventoryObjects._lengthObjectTypeIds(entityId) == 0, "Cannot build where there are dropped objects");

    ObjectType._set(entityId, objectTypeId);

    return entityId;
  }

  function buildWithExtraData(
    uint8 objectTypeId,
    VoxelCoord memory coord,
    bytes memory extraData
  ) public payable returns (bytes32) {
    require(ObjectTypeMetadata._getCategory(objectTypeId) == ObjectCategory.Block, "Cannot build non-block object");
    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, coord);

    bytes32 baseEntityId = buildObjectAtCoord(objectTypeId, coord);
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

    // Note: we call this after the build state has been updated, to prevent re-entrancy attacks
    callInternalSystem(
      abi.encodeCall(
        IForceFieldSystem.requireBuildsAllowed,
        (playerEntityId, baseEntityId, objectTypeId, coords, extraData)
      ),
      _msgValue()
    );

    return baseEntityId;
  }

  function jumpBuildWithExtraData(uint8 objectTypeId, bytes memory extraData) public payable {
    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    VoxelCoord memory jumpCoord = VoxelCoord(playerCoord.x, playerCoord.y + 1, playerCoord.z);
    require(inWorldBorder(jumpCoord), "BuildSystem: cannot jump outside world border");
    bytes32 newEntityId = ReversePosition._get(jumpCoord.x, jumpCoord.y, jumpCoord.z);
    if (newEntityId == bytes32(0)) {
      // Check terrain block type
      uint8 terrainObjectTypeId = getTerrainObjectTypeId(jumpCoord);
      require(
        terrainObjectTypeId == AirObjectID || terrainObjectTypeId == WaterObjectID,
        "BuildSystem: cannot move to non-air block"
      );
      newEntityId = getUniqueEntity();
      ObjectType._set(newEntityId, AirObjectID);
    } else {
      require(ObjectType._get(newEntityId) == AirObjectID, "BuildSystem: cannot move to non-air block");
      transferAllInventoryEntities(newEntityId, playerEntityId, PlayerObjectID);
    }

    // Swap entity ids
    ReversePosition._set(playerCoord.x, playerCoord.y, playerCoord.z, newEntityId);
    Position._set(newEntityId, playerCoord.x, playerCoord.y, playerCoord.z);

    Position._set(playerEntityId, jumpCoord.x, jumpCoord.y, jumpCoord.z);
    ReversePosition._set(jumpCoord.x, jumpCoord.y, jumpCoord.z, playerEntityId);

    {
      uint32 useStamina = 1;
      uint32 currentStamina = Stamina._getStamina(playerEntityId);
      require(currentStamina >= useStamina, "BuildSystem: not enough stamina");
      Stamina._setStamina(playerEntityId, currentStamina - useStamina);
    }

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Move,
        entityId: newEntityId,
        objectTypeId: PlayerObjectID,
        coordX: jumpCoord.x,
        coordY: jumpCoord.y,
        coordZ: jumpCoord.z,
        amount: 1
      })
    );

    buildWithExtraData(objectTypeId, playerCoord, extraData);
  }

  function jumpBuild(uint8 objectTypeId) public payable {
    jumpBuildWithExtraData(objectTypeId, new bytes(0));
  }

  function build(uint8 objectTypeId, VoxelCoord memory coord) public payable returns (bytes32) {
    return buildWithExtraData(objectTypeId, coord, new bytes(0));
  }
}
