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
import { Stamina } from "../codegen/tables/Stamina.sol";
import { ActionType } from "../codegen/common.sol";

import { MAX_PLAYER_INFLUENCE_HALF_WIDTH } from "../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { inSpawnArea, inWorldBorder, getTerrainObjectTypeId, getUniqueEntity, callMintXP } from "../Utils.sol";
import { removeFromInventoryCount, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";

import { IForceFieldSystem } from "../codegen/world/IForceFieldSystem.sol";

contract BuildSystem is System {
  function buildCommon(uint8 objectTypeId, VoxelCoord memory coord) internal returns (bytes32) {
    require(inWorldBorder(coord), "BuildSystem: cannot build outside world border");
    require(!inSpawnArea(coord), "BuildSystem: cannot build at spawn area");
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

  function build(uint8 objectTypeId, VoxelCoord memory coord, bytes memory extraData) public payable returns (bytes32) {
    uint256 initialGas = gasleft();

    require(ObjectTypeMetadata._getIsBlock(objectTypeId), "BuildSystem: object type is not a block");
    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, coord);

    bytes32 baseEntityId = buildCommon(objectTypeId, coord);
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
        bytes32 entityId = buildCommon(objectTypeId, relativeCoord);
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

  function jumpBuild(uint8 objectTypeId, bytes memory extraData) public payable {
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

    build(objectTypeId, playerCoord, extraData);
  }

  function jumpBuild(uint8 objectTypeId) public payable {
    jumpBuild(objectTypeId, new bytes(0));
  }

  function build(uint8 objectTypeId, VoxelCoord memory coord) public payable returns (bytes32) {
    return build(objectTypeId, coord, new bytes(0));
  }
}
