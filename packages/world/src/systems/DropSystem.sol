// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ActionType } from "../codegen/common.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";

import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { getUniqueEntity } from "../Utils.sol";
import { Vec3 } from "../Vec3.sol";
import { getOrCreateEntityAt } from "../utils/EntityUtils.sol";
import { transferInventoryEntity, transferInventoryNonEntity } from "../utils/InventoryUtils.sol";
import { DropNotification, notify } from "../utils/NotifUtils.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";

// TODO: combine the tool and non-tool drop functions
contract DropSystem is System {
  function dropCommon(EntityId caller, Vec3 coord) internal returns (EntityId) {
    caller.activate();
    caller.requireConnected(coord);

    (EntityId entityId, ObjectTypeId objectTypeId) = getOrCreateEntityAt(coord);
    require(ObjectTypeMetadata.getCanPassThrough(objectTypeId), "Cannot drop on a non-passable block");

    return entityId;
  }

  function drop(EntityId caller, ObjectTypeId dropObjectTypeId, uint16 numToDrop, Vec3 coord) public {
    EntityId entityId = dropCommon(caller, coord);
    transferInventoryNonEntity(caller, entityId, ObjectType._get(entityId), dropObjectTypeId, numToDrop);

    notify(
      caller, DropNotification({ dropCoord: coord, dropObjectTypeId: dropObjectTypeId, dropAmount: numToDrop })
    );
  }

  function dropTool(EntityId caller, EntityId tool, Vec3 coord) public {
    EntityId entityId = dropCommon(caller, coord);
    ObjectTypeId toolObjectTypeId =
      transferInventoryEntity(caller, entityId, ObjectType._get(entityId), tool);

    notify(caller, DropNotification({ dropCoord: coord, dropObjectTypeId: toolObjectTypeId, dropAmount: 1 }));
  }

  function dropTools(EntityId caller, EntityId[] memory tools, Vec3 coord) public {
    require(tools.length > 0, "Must drop at least one tool");

    EntityId entityId = dropCommon(caller, coord);

    ObjectTypeId toolObjectTypeId;
    for (uint256 i = 0; i < tools.length; i++) {
      ObjectTypeId currentToolObjectTypeId =
        transferInventoryEntity(caller, entityId, ObjectTypes.Air, tools[i]);
      if (i > 0) {
        require(toolObjectTypeId == currentToolObjectTypeId, "All tools must be of the same type");
      } else {
        toolObjectTypeId = currentToolObjectTypeId;
      }
    }

    notify(
      caller,
      DropNotification({ dropCoord: coord, dropObjectTypeId: toolObjectTypeId, dropAmount: uint16(tools.length) })
    );
  }
}
