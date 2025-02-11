// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { OptionalSystemHooks } from "@latticexyz/world/src/codegen/tables/OptionalSystemHooks.sol";
import { UserDelegationControl } from "@latticexyz/world/src/codegen/tables/UserDelegationControl.sol";
import { VoxelCoord } from "../../Types.sol";

import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../../codegen/tables/BaseEntity.sol";
import { Position } from "../../codegen/tables/Position.sol";
import { ReversePosition } from "../../codegen/tables/ReversePosition.sol";
import { LastKnownPosition } from "../../codegen/tables/LastKnownPosition.sol";
import { Player } from "../../codegen/tables/Player.sol";
import { PlayerActivity } from "../../codegen/tables/PlayerActivity.sol";
import { PlayerStatus } from "../../codegen/tables/PlayerStatus.sol";
import { ObjectTypeMetadata } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { InventoryCount } from "../../codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../../codegen/tables/InventoryObjects.sol";
import { ReverseInventoryTool } from "../../codegen/tables/ReverseInventoryTool.sol";

import { getEntityInventory } from "../../utils/ReadUtils.sol";
import { NullObjectTypeId, PlayerObjectID } from "../../ObjectTypeIds.sol";
import { lastKnownPositionDataToVoxelCoord, positionDataToVoxelCoord } from "../../Utils.sol";
import { InventoryObject, EntityData } from "../../Types.sol";
import { EntityId } from "../../EntityId.sol";

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

  function getObjectTypeIdAtCoord(VoxelCoord memory coord) public view returns (uint16) {
    EntityId entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    if (!entityId.exists()) {
      return NullObjectTypeId;
    }
    return ObjectType._get(entityId);
  }

  function getEntityIdAtCoord(VoxelCoord memory coord) public view returns (EntityId) {
    return ReversePosition._get(coord.x, coord.y, coord.z);
  }

  function getEntityData(EntityId entityId) public view returns (EntityData memory) {
    if (!entityId.exists()) {
      return
        EntityData({
          objectTypeId: NullObjectTypeId,
          entityId: EntityId.wrap(0),
          baseEntityId: EntityId.wrap(0),
          inventory: new InventoryObject[](0),
          position: VoxelCoord(0, 0, 0)
        });
    }

    EntityId baseEntityId = entityId.baseEntityId();

    return
      EntityData({
        objectTypeId: ObjectType._get(entityId),
        entityId: entityId,
        baseEntityId: baseEntityId,
        inventory: getInventory(baseEntityId),
        position: getCoordForEntityId(entityId)
      });
  }

  function getEntityDataAtCoord(VoxelCoord memory coord) public view returns (EntityData memory) {
    EntityId entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    if (!entityId.exists()) {
      return
        EntityData({
          objectTypeId: NullObjectTypeId,
          entityId: EntityId.wrap(0),
          baseEntityId: EntityId.wrap(0),
          inventory: new InventoryObject[](0),
          position: coord
        });
    }

    EntityId baseEntityId = entityId.baseEntityId();

    return
      EntityData({
        objectTypeId: ObjectType._get(entityId),
        entityId: entityId,
        baseEntityId: baseEntityId,
        inventory: getInventory(baseEntityId),
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

  function getLastActivityTime(address player) public view returns (uint256) {
    EntityId playerEntityId = Player._get(player);
    if (PlayerStatus._getIsLoggedOff(playerEntityId)) {
      return 0;
    }
    return PlayerActivity._get(playerEntityId);
  }

  function getInventory(address player) public view returns (InventoryObject[] memory) {
    EntityId playerEntityId = Player._get(player);
    require(playerEntityId.exists(), "Player not found");
    return getInventory(playerEntityId);
  }

  function getInventory(EntityId entityId) public view returns (InventoryObject[] memory) {
    return getEntityInventory(entityId);
  }

  function getCoordForEntityId(EntityId entityId) public view returns (VoxelCoord memory) {
    uint16 objectTypeId = ObjectType._get(entityId);
    if (objectTypeId == PlayerObjectID && PlayerStatus._getIsLoggedOff(entityId)) {
      return lastKnownPositionDataToVoxelCoord(LastKnownPosition._get(entityId));
    } else {
      return positionDataToVoxelCoord(Position._get(entityId));
    }
  }

  function getPlayerCoord(address player) public view returns (VoxelCoord memory) {
    EntityId playerEntityId = Player._get(player);
    require(playerEntityId.exists(), "Player not found");
    return getCoordForEntityId(playerEntityId);
  }
}
