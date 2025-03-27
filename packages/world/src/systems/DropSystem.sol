// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { ActionType } from "../codegen/common.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { getUniqueEntity } from "../Utils.sol";
import { transferInventoryNonEntity, transferInventoryEntity } from "../utils/InventoryUtils.sol";
import { notify, DropNotifData } from "../utils/NotifUtils.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";
import { EntityId } from "../EntityId.sol";
import { Vec3 } from "../Vec3.sol";
import { getOrCreateEntityAt } from "../utils/EntityUtils.sol";

// TODO: combine the tool and non-tool drop functions
contract DropSystem is System {
  function dropCommon(EntityId callerEntityId, Vec3 coord) internal returns (EntityId) {
    callerEntityId.activate();
    callerEntityId.requireConnected(coord);

    (EntityId entityId, ObjectTypeId objectTypeId) = getOrCreateEntityAt(coord);
    require(ObjectTypeMetadata.getCanPassThrough(objectTypeId), "Cannot drop on a non-passable block");

    return entityId;
  }

  function drop(EntityId callerEntityId, ObjectTypeId dropObjectTypeId, uint16 numToDrop, Vec3 coord) public {
    EntityId entityId = dropCommon(callerEntityId, coord);
    transferInventoryNonEntity(callerEntityId, entityId, ObjectType._get(entityId), dropObjectTypeId, numToDrop);

    notify(
      callerEntityId,
      DropNotifData({ dropCoord: coord, dropObjectTypeId: dropObjectTypeId, dropAmount: numToDrop })
    );
  }

  function dropTool(EntityId callerEntityId, EntityId toolEntityId, Vec3 coord) public {
    EntityId entityId = dropCommon(callerEntityId, coord);
    ObjectTypeId toolObjectTypeId = transferInventoryEntity(
      callerEntityId,
      entityId,
      ObjectType._get(entityId),
      toolEntityId
    );

    notify(callerEntityId, DropNotifData({ dropCoord: coord, dropObjectTypeId: toolObjectTypeId, dropAmount: 1 }));
  }

  function dropTools(EntityId callerEntityId, EntityId[] memory toolEntityIds, Vec3 coord) public {
    require(toolEntityIds.length > 0, "Must drop at least one tool");

    EntityId entityId = dropCommon(callerEntityId, coord);

    ObjectTypeId toolObjectTypeId;
    for (uint i = 0; i < toolEntityIds.length; i++) {
      ObjectTypeId currentToolObjectTypeId = transferInventoryEntity(
        callerEntityId,
        entityId,
        ObjectTypes.Air,
        toolEntityIds[i]
      );
      if (i > 0) {
        require(toolObjectTypeId == currentToolObjectTypeId, "All tools must be of the same type");
      } else {
        toolObjectTypeId = currentToolObjectTypeId;
      }
    }

    notify(
      callerEntityId,
      DropNotifData({ dropCoord: coord, dropObjectTypeId: toolObjectTypeId, dropAmount: uint16(toolEntityIds.length) })
    );
  }
}
