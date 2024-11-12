// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { OptionalSystemHooks } from "@latticexyz/world/src/codegen/tables/OptionalSystemHooks.sol";
import { UserDelegationControl } from "@latticexyz/world/src/codegen/tables/UserDelegationControl.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../../codegen/tables/BaseEntity.sol";
import { Position } from "../../codegen/tables/Position.sol";
import { ReversePosition } from "../../codegen/tables/ReversePosition.sol";
import { LastKnownPosition } from "../../codegen/tables/LastKnownPosition.sol";
import { Player } from "../../codegen/tables/Player.sol";
import { Health, HealthData } from "../../codegen/tables/Health.sol";
import { Stamina, StaminaData } from "../../codegen/tables/Stamina.sol";
import { PlayerActivity } from "../../codegen/tables/PlayerActivity.sol";
import { PlayerMetadata } from "../../codegen/tables/PlayerMetadata.sol";
import { ObjectTypeMetadata } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { InventoryCount } from "../../codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../../codegen/tables/InventoryObjects.sol";
import { ReverseInventoryTool } from "../../codegen/tables/ReverseInventoryTool.sol";
import { ItemMetadata } from "../../codegen/tables/ItemMetadata.sol";

import { getTerrainObjectTypeId, lastKnownPositionDataToVoxelCoord, positionDataToVoxelCoord } from "../../Utils.sol";
import { getEntityInventory } from "../../utils/ReadUtils.sol";
import { NullObjectTypeId, PlayerObjectID } from "../../ObjectTypeIds.sol";
import { InventoryObject, InventoryTool, EntityData, EntityDataWithBaseEntity } from "../../Types.sol";

// Public getters so clients can read the world state more easily
contract ReadSystem is System {
  function getOptionalSystemHooks(
    address player,
    ResourceId SystemId,
    bytes32 callDataHash
  ) public view returns (bytes21[] memory hooks) {
    return OptionalSystemHooks._getHooks(player, SystemId, callDataHash);
  }

  function getUserDelegation(
    address delegator,
    address delegatee
  ) public view returns (ResourceId delegationControlId) {
    return UserDelegationControl._getDelegationControlId(delegator, delegatee);
  }

  function getObjectTypeIdAtCoord(VoxelCoord memory coord) public view returns (uint8) {
    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    if (entityId == bytes32(0)) {
      return NullObjectTypeId;
    }
    return ObjectType._get(entityId);
  }

  function getObjectTypeIdAtCoordOrTerrain(VoxelCoord memory coord) public view returns (uint8) {
    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    if (entityId == bytes32(0)) {
      return getTerrainObjectTypeId(coord);
    }
    return ObjectType._get(entityId);
  }

  function getMultipleObjectTypeIdAtCoordOrTerrain(VoxelCoord[] memory coord) public view returns (uint8[] memory) {
    uint8[] memory objectTypes = new uint8[](coord.length);
    for (uint256 i = 0; i < coord.length; i++) {
      objectTypes[i] = getObjectTypeIdAtCoordOrTerrain(coord[i]);
    }
    return objectTypes;
  }

  function getEntityIdAtCoord(VoxelCoord memory coord) public view returns (bytes32) {
    return ReversePosition._get(coord.x, coord.y, coord.z);
  }

  function getEntityData(bytes32 entityId) public view returns (EntityData memory) {
    if (entityId == bytes32(0)) {
      return
        EntityData({
          objectTypeId: NullObjectTypeId,
          entityId: bytes32(0),
          inventory: new InventoryObject[](0),
          position: VoxelCoord(0, 0, 0)
        });
    }

    return
      EntityData({
        objectTypeId: ObjectType._get(entityId),
        entityId: entityId,
        inventory: getInventory(entityId),
        position: getCoordForEntityId(entityId)
      });
  }

  function getEntityDataAtCoord(VoxelCoord memory coord) public view returns (EntityData memory) {
    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    if (entityId == bytes32(0)) {
      return
        EntityData({
          objectTypeId: getTerrainObjectTypeId(coord),
          entityId: bytes32(0),
          inventory: new InventoryObject[](0),
          position: coord
        });
    }
    return
      EntityData({
        objectTypeId: ObjectType._get(entityId),
        entityId: entityId,
        inventory: getInventory(entityId),
        position: coord
      });
  }

  function getMultipleEntityDataAtCoord(VoxelCoord[] memory coord) public view returns (EntityData[] memory) {
    EntityData[] memory entityData = new EntityData[](coord.length);
    for (uint256 i = 0; i < coord.length; i++) {
      entityData[i] = getEntityDataAtCoord(coord[i]);
    }
    return entityData;
  }

  function getEntityDataWithBaseEntity(bytes32 entityId) public view returns (EntityDataWithBaseEntity memory) {
    if (entityId == bytes32(0)) {
      return
        EntityDataWithBaseEntity({
          objectTypeId: NullObjectTypeId,
          entityId: bytes32(0),
          baseEntityId: bytes32(0),
          inventory: new InventoryObject[](0),
          position: VoxelCoord(0, 0, 0)
        });
    }

    bytes32 baseEntityId = BaseEntity._get(entityId);

    return
      EntityDataWithBaseEntity({
        objectTypeId: ObjectType._get(entityId),
        entityId: entityId,
        baseEntityId: baseEntityId,
        inventory: getInventory(baseEntityId == bytes32(0) ? entityId : baseEntityId),
        position: getCoordForEntityId(entityId)
      });
  }

  function getEntityDataWithBaseEntityAtCoord(
    VoxelCoord memory coord
  ) public view returns (EntityDataWithBaseEntity memory) {
    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    if (entityId == bytes32(0)) {
      return
        EntityDataWithBaseEntity({
          objectTypeId: getTerrainObjectTypeId(coord),
          entityId: bytes32(0),
          baseEntityId: bytes32(0),
          inventory: new InventoryObject[](0),
          position: coord
        });
    }

    bytes32 baseEntityId = BaseEntity._get(entityId);

    return
      EntityDataWithBaseEntity({
        objectTypeId: ObjectType._get(entityId),
        entityId: entityId,
        baseEntityId: baseEntityId,
        inventory: getInventory(baseEntityId == bytes32(0) ? entityId : baseEntityId),
        position: coord
      });
  }

  function getMultipleEntityDataWithBaseEntityAtCoord(
    VoxelCoord[] memory coord
  ) public view returns (EntityDataWithBaseEntity[] memory) {
    EntityDataWithBaseEntity[] memory entityData = new EntityDataWithBaseEntity[](coord.length);
    for (uint256 i = 0; i < coord.length; i++) {
      entityData[i] = getEntityDataWithBaseEntityAtCoord(coord[i]);
    }
    return entityData;
  }

  function getLastActivityTime(address player) public view returns (uint256) {
    bytes32 playerEntityId = Player._get(player);
    if (PlayerMetadata._getIsLoggedOff(playerEntityId)) {
      return 0;
    }
    return PlayerActivity._get(playerEntityId);
  }

  function getHealth(address player) public view returns (HealthData memory) {
    bytes32 playerEntityId = Player._get(player);
    require(playerEntityId != bytes32(0), "ReadSystem: player not found");
    return Health._get(playerEntityId);
  }

  function getStamina(address player) public view returns (StaminaData memory) {
    bytes32 playerEntityId = Player._get(player);
    require(playerEntityId != bytes32(0), "ReadSystem: player not found");
    return Stamina._get(playerEntityId);
  }

  function getInventory(address player) public view returns (InventoryObject[] memory) {
    bytes32 playerEntityId = Player._get(player);
    require(playerEntityId != bytes32(0), "ReadSystem: player not found");
    return getInventory(playerEntityId);
  }

  function getInventory(bytes32 entityId) public view returns (InventoryObject[] memory) {
    return getEntityInventory(entityId);
  }

  function getCoordForEntityId(bytes32 entityId) public view returns (VoxelCoord memory) {
    uint8 objectTypeId = ObjectType._get(entityId);
    if (objectTypeId == PlayerObjectID && PlayerMetadata._getIsLoggedOff(entityId)) {
      return lastKnownPositionDataToVoxelCoord(LastKnownPosition._get(entityId));
    } else {
      return positionDataToVoxelCoord(Position._get(entityId));
    }
  }

  function getPlayerCoord(address player) public view returns (VoxelCoord memory) {
    bytes32 playerEntityId = Player._get(player);
    require(playerEntityId != bytes32(0), "ReadSystem: player not found");
    return getCoordForEntityId(playerEntityId);
  }
}
