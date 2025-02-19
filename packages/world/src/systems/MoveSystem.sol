// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord, VoxelCoordDirection } from "../VoxelCoord.sol";

import { ObjectTypeSchema, ObjectTypeSchemaData } from "../codegen/tables/ObjectTypeSchema.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { PlayerPosition } from "../codegen/tables/PlayerPosition.sol";
import { ReversePlayerPosition } from "../codegen/tables/ReversePlayerPosition.sol";
import { ActionType } from "../codegen/common.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";

import { ObjectTypeId, AirObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { gravityApplies, inWorldBorder } from "../Utils.sol";
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

    ObjectTypeSchemaData memory schemaData = ObjectTypeSchema._get(PlayerObjectID);
    VoxelCoord memory oldCoord = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z);

    EntityId[] memory relativeEntityIds = new EntityId[](schemaData.relativePositionsX.length);
    VoxelCoord[] memory relativeCoords = new VoxelCoord[](schemaData.relativePositionsX.length);
    for (uint256 i = 0; i < schemaData.relativePositionsX.length; i++) {
      VoxelCoord memory relativeCoord = VoxelCoord(
        playerCoord.x + schemaData.relativePositionsX[i],
        playerCoord.y + schemaData.relativePositionsY[i],
        playerCoord.z + schemaData.relativePositionsZ[i]
      );
      relativeEntityIds[i] = relativeCoord.getPlayer();
      relativeCoords[i] = relativeCoord;
      // TODO: do we need this check?
      require(relativeEntityIds[i].baseEntityId() == playerEntityId, "Base entity mismatch");
    }

    EntityId finalEntityId;
    bool gravityAppliesForCoord = false;
    uint256 numJumps = 0;
    uint256 numFalls = 0;
    uint256 numGlides = 0;
    for (uint256 i = 0; i < newCoords.length; i++) {
      VoxelCoord memory newCoord = newCoords[i];
      (finalEntityId, gravityAppliesForCoord) = move(playerEntityId, oldCoord, newCoord);

      for (uint256 j = 0; j < schemaData.relativePositionsX.length; j++) {
        VoxelCoord memory oldRelativeCoord = VoxelCoord(
          oldCoord.x + schemaData.relativePositionsX[j],
          oldCoord.y + schemaData.relativePositionsY[j],
          oldCoord.z + schemaData.relativePositionsZ[j]
        );
        VoxelCoord memory newRelativeCoord = VoxelCoord(
          newCoord.x + schemaData.relativePositionsX[j],
          newCoord.y + schemaData.relativePositionsY[j],
          newCoord.z + schemaData.relativePositionsZ[j]
        );
        move(relativeEntityIds[j], oldRelativeCoord, newRelativeCoord);
      }

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
    if (!finalEntityId.exists()) {
      finalCoord.getOrCreateEntity();
    }

    playerCoord.removePlayer();
    finalCoord.setPlayer(playerEntityId);

    for (uint256 i = 0; i < schemaData.relativePositionsX.length; i++) {
      relativeCoords[i].removePlayer();
      VoxelCoord memory newRelativeCoord = VoxelCoord(
        finalCoord.x + schemaData.relativePositionsX[i],
        finalCoord.y + schemaData.relativePositionsY[i],
        finalCoord.z + schemaData.relativePositionsZ[i]
      );
      newRelativeCoord.getOrCreateEntity();
      newRelativeCoord.setPlayer(relativeEntityIds[i]);
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

    {
      VoxelCoord memory aboveCoord = VoxelCoord(playerCoord.x, playerCoord.y + 1, playerCoord.z);
      EntityId aboveEntityId = aboveCoord.getPlayer();
      if (aboveEntityId.exists()) {
        GravityLib.runGravity(aboveEntityId, aboveCoord);
      }
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

    (EntityId newEntityId, ObjectTypeId newObjectTypeId) = newCoord.getEntity();
    require(ObjectTypeMetadata._getCanPassThrough(newObjectTypeId), "Cannot move through a non-passable block");

    EntityId playerEntityIdAtCoord = newCoord.getPlayer();
    // If the entity we're moving into is this player, then it's fine as
    // the player will be moved from the old position to the new position
    require(!playerEntityIdAtCoord.exists() || playerEntityIdAtCoord == playerEntityId, "Cannot move through a player");

    return (newEntityId, gravityApplies(newCoord));
  }
}
