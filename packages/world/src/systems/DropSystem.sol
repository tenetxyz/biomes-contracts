// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "../VoxelCoord.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { ActionType } from "../codegen/common.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";

import { ObjectTypeId, AirObjectID } from "../ObjectTypeIds.sol";
import { inWorldBorder, getUniqueEntity } from "../Utils.sol";
import { transferInventoryNonEntity, transferInventoryEntity } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { notify, DropNotifData } from "../utils/NotifUtils.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";
import { EntityId } from "../EntityId.sol";
import { PLAYER_DROP_ENERGY_COST } from "../Constants.sol";
import { transferEnergyToPool } from "../utils/EnergyUtils.sol";

// TODO: combine the tool and non-tool drop functions
contract DropSystem is System {
  function dropCommon(VoxelCoord memory coord) internal returns (EntityId, EntityId) {
    require(inWorldBorder(coord), "Cannot drop outside the world border");
    (EntityId playerEntityId, VoxelCoord memory playerCoord, ) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, coord);

    (EntityId entityId, ObjectTypeId objectTypeId) = coord.getOrCreateEntity();
    require(objectTypeId == AirObjectID, "Cannot drop on a non-air block");

    transferEnergyToPool(playerEntityId, playerCoord, PLAYER_DROP_ENERGY_COST);

    return (playerEntityId, entityId);
  }

  function drop(ObjectTypeId dropObjectTypeId, uint16 numToDrop, VoxelCoord memory coord) public {
    (EntityId playerEntityId, EntityId entityId) = dropCommon(coord);
    transferInventoryNonEntity(playerEntityId, entityId, AirObjectID, dropObjectTypeId, numToDrop);

    notify(
      playerEntityId,
      DropNotifData({ dropCoord: coord, dropObjectTypeId: dropObjectTypeId, dropAmount: numToDrop })
    );
  }

  function dropTool(EntityId toolEntityId, VoxelCoord memory coord) public {
    (EntityId playerEntityId, EntityId entityId) = dropCommon(coord);
    ObjectTypeId toolObjectTypeId = transferInventoryEntity(playerEntityId, entityId, AirObjectID, toolEntityId);

    notify(playerEntityId, DropNotifData({ dropCoord: coord, dropObjectTypeId: toolObjectTypeId, dropAmount: 1 }));
  }

  function dropTools(EntityId[] memory toolEntityIds, VoxelCoord memory coord) public {
    require(toolEntityIds.length > 0, "Must drop at least one tool");

    (EntityId playerEntityId, EntityId entityId) = dropCommon(coord);

    ObjectTypeId toolObjectTypeId;
    for (uint i = 0; i < toolEntityIds.length; i++) {
      ObjectTypeId currentToolObjectTypeId = transferInventoryEntity(
        playerEntityId,
        entityId,
        AirObjectID,
        toolEntityIds[i]
      );
      if (i > 0) {
        require(toolObjectTypeId == currentToolObjectTypeId, "All tools must be of the same type");
      } else {
        toolObjectTypeId = currentToolObjectTypeId;
      }
    }

    notify(
      playerEntityId,
      DropNotifData({ dropCoord: coord, dropObjectTypeId: toolObjectTypeId, dropAmount: uint16(toolEntityIds.length) })
    );
  }
}
