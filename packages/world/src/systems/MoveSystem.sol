// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord, VoxelCoordDirection } from "../VoxelCoord.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { ActionType } from "../codegen/common.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";

import { ObjectTypeId, AirObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { gravityApplies, inWorldBorder } from "../Utils.sol";
import { transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { PLAYER_MOVE_ENERGY_COST } from "../Constants.sol";
import { notify, MoveNotifData } from "../utils/NotifUtils.sol";
import { GravityLib } from "./libraries/GravityLib.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";
import { EntityId } from "../EntityId.sol";
import { transferEnergyFromPlayerToPool } from "../utils/EnergyUtils.sol";
import { requireValidPlayer } from "../utils/PlayerUtils.sol";

import { EntityId } from "../EntityId.sol";

contract MoveSystem is System {
  function move(VoxelCoord[] memory newCoords) public {
    (EntityId playerEntityId, VoxelCoord memory playerCoord, EnergyData memory playerEnergyData) = requireValidPlayer(
      _msgSender()
    );

    MoveLib.movePlayer(playerEntityId, playerCoord, playerEnergyData, newCoords);
  }

  function moveDirections(VoxelCoordDirection[] memory directions) public {
    (EntityId playerEntityId, VoxelCoord memory playerCoord, EnergyData memory playerEnergyData) = requireValidPlayer(
      _msgSender()
    );

    VoxelCoord[] memory newCoords = new VoxelCoord[](directions.length);
    for (uint256 i = 0; i < directions.length; i++) {
      newCoords[i] = (i == 0 ? playerCoord : newCoords[i - 1]).transform(directions[i]);
    }

    MoveLib.movePlayer(playerEntityId, playerCoord, playerEnergyData, newCoords);
  }
}

library MoveLib {
  function movePlayer(
    EntityId playerEntityId,
    VoxelCoord memory playerCoord,
    EnergyData memory playerEnergyData,
    VoxelCoord[] memory newCoords
  ) public {
    // no-ops
    if (newCoords.length == 0) {
      return;
    }

    VoxelCoord memory oldCoord = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z);

    EntityId finalEntityId;
    bool gravityAppliesForCoord = false;
    uint256 numJumps = 0;
    uint256 numFalls = 0;
    uint256 numGlides = 0;
    for (uint256 i = 0; i < newCoords.length; i++) {
      VoxelCoord memory newCoord = newCoords[i];
      (finalEntityId, gravityAppliesForCoord) = move(playerEntityId, oldCoord, newCoord);
      if (gravityAppliesForCoord) {
        if (oldCoord.y < newCoord.y) {
          numJumps++;
          require(numJumps <= 3, "Cannot jump more than 3 blocks");
        } else if (oldCoord.y > newCoord.y) {
          // then we are falling, so should be fine
          numFalls++;
          numGlides = 0;
        } else {
          // we are gliding
          numGlides++;
          require(numGlides <= 10, "Cannot glide more than 10 blocks");
        }
      } else {
        numJumps = 0;
        numGlides = 0;
      }
      oldCoord = VoxelCoord(newCoord.x, newCoord.y, newCoord.z);
    }

    VoxelCoord memory finalCoord = newCoords[newCoords.length - 1];
    if (finalEntityId != playerEntityId) {
      transferAllInventoryEntities(finalEntityId, playerEntityId, PlayerObjectID);

      // Swap entity ids
      ReversePosition._set(playerCoord.x, playerCoord.y, playerCoord.z, finalEntityId);
      Position._set(finalEntityId, playerCoord.x, playerCoord.y, playerCoord.z);

      Position._set(playerEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
      ReversePosition._set(finalCoord.x, finalCoord.y, finalCoord.z, playerEntityId);
    }

    transferEnergyFromPlayerToPool(
      playerEntityId,
      playerCoord,
      playerEnergyData,
      PLAYER_MOVE_ENERGY_COST * uint128(newCoords.length)
    );

    if (gravityAppliesForCoord) {
      GravityLib.runGravity(playerEntityId, finalCoord);
    }

    VoxelCoord memory aboveCoord = VoxelCoord(playerCoord.x, playerCoord.y + 1, playerCoord.z);
    EntityId aboveEntityId = ReversePosition._get(aboveCoord.x, aboveCoord.y, aboveCoord.z);
    if (aboveEntityId.exists() && ObjectType._get(aboveEntityId) == PlayerObjectID) {
      GravityLib.runGravity(aboveEntityId, aboveCoord);
    }

    notify(playerEntityId, MoveNotifData({ moveCoords: newCoords }));
  }

  function move(
    EntityId playerEntityId,
    VoxelCoord memory oldCoord,
    VoxelCoord memory newCoord
  ) internal view returns (EntityId, bool) {
    require(inWorldBorder(newCoord), "Cannot move outside the world border");
    require(oldCoord.inSurroundingCube(1, newCoord), "New coord is too far from old coord");

    EntityId newEntityId = ReversePosition._get(newCoord.x, newCoord.y, newCoord.z);
    if (!newEntityId.exists()) {
      ObjectTypeId terrainObjectTypeId = ObjectTypeId.wrap(TerrainLib._getBlockType(newCoord));
      require(terrainObjectTypeId == AirObjectID, "Cannot move through a non-air block");
    } else {
      // If the entity we're moving into is this player, then it's fine as
      // the player will be moved from the old position to the new position
      if (playerEntityId != newEntityId) {
        ObjectTypeId currentObjectTypeId = ObjectType._get(newEntityId);
        // TODO: check for water and florae
        require(currentObjectTypeId == AirObjectID, "Cannot move through a non-air block");
      }
    }

    return (newEntityId, gravityApplies(newCoord));
  }
}
