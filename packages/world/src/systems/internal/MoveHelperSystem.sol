// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { inSurroundingCube, voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { Position } from "../../codegen/tables/Position.sol";
import { BaseEntity } from "../../codegen/tables/BaseEntity.sol";
import { ReversePosition } from "../../codegen/tables/ReversePosition.sol";
import { Stamina } from "../../codegen/tables/Stamina.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../../codegen/common.sol";
import { ObjectTypeSchema, ObjectTypeSchemaData } from "../../codegen/tables/ObjectTypeSchema.sol";

import { PLAYER_MASS, GRAVITY_STAMINA_COST, MAX_PLAYER_STAMINA } from "../../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID } from "../../ObjectTypeIds.sol";
import { callGravity, gravityApplies, inWorldBorder, getTerrainObjectTypeId, getUniqueEntity, callMintXP } from "../../Utils.sol";
import { transferAllInventoryEntities } from "../../utils/InventoryUtils.sol";
import { requireValidPlayer } from "../../utils/PlayerUtils.sol";

contract MoveHelperSystem is System {
  function movePlayer(
    bytes32 playerEntityId,
    VoxelCoord memory playerCoord,
    VoxelCoord[] memory newCoords
  ) public returns (bytes32[] memory finalEntityIds, VoxelCoord[] memory finalCoords, bool gravityApplies) {
    ObjectTypeSchemaData memory schemaData = ObjectTypeSchema._get(PlayerObjectID);
    bytes32[] memory initialEntityIds = new bytes32[](schemaData.relativePositionsX.length + 1);
    initialEntityIds[0] = playerEntityId;
    VoxelCoord[] memory initialCoords = new VoxelCoord[](schemaData.relativePositionsX.length + 1);
    initialCoords[0] = playerCoord;
    for (uint256 i = 0; i < schemaData.relativePositionsX.length; i++) {
      VoxelCoord memory relativeCoord = VoxelCoord(
        playerCoord.x + schemaData.relativePositionsX[i],
        playerCoord.y + schemaData.relativePositionsY[i],
        playerCoord.z + schemaData.relativePositionsZ[i]
      );
      initialEntityIds[i + 1] = ReversePosition._get(relativeCoord.x, relativeCoord.y, relativeCoord.z);
      require(BaseEntity._get(initialEntityIds[i + 1]) == playerEntityId, "MoveSystem: initial entity id mismatch");
      initialCoords[i + 1] = relativeCoord;
    }

    uint256 numFalls;
    (finalEntityIds, finalCoords, gravityApplies, numFalls) = checkMovePath(playerEntityId, playerCoord, newCoords);
    require(
      finalEntityIds.length == initialEntityIds.length && finalCoords.length == initialCoords.length,
      "MoveSystem: final entity ids length mismatch"
    );

    {
      uint256 staminaRequired = (PLAYER_MASS * (newCoords.length ** 2)) / 100;
      staminaRequired += numFalls > 5 ? (GRAVITY_STAMINA_COST * numFalls) : 0;
      require(staminaRequired <= MAX_PLAYER_STAMINA, "MoveSystem: stamina required exceeds max player stamina");
      uint32 useStamina = staminaRequired == 0 ? 1 : uint32(staminaRequired);

      uint32 currentStamina = Stamina._getStamina(playerEntityId);
      require(currentStamina >= useStamina, "MoveSystem: not enough stamina");
      Stamina._setStamina(playerEntityId, currentStamina - useStamina);
    }

    if (finalEntityIds[0] != playerEntityId) {
      for (uint256 i = 0; i < finalEntityIds.length; i++) {
        bytes32 finalEntityId = finalEntityIds[i];
        VoxelCoord memory finalCoord = finalCoords[i];
        if (finalEntityId == bytes32(0)) {
          finalEntityId = getUniqueEntity();
          ObjectType._set(finalEntityId, AirObjectID);
        } else {
          transferAllInventoryEntities(finalEntityId, playerEntityId, PlayerObjectID);
        }
        bytes32 initialEntityId = initialEntityIds[i];
        VoxelCoord memory initialCoord = initialCoords[i];

        // Swap entity ids
        ReversePosition._set(initialCoord.x, initialCoord.y, initialCoord.z, finalEntityId);
        Position._set(finalEntityId, initialCoord.x, initialCoord.y, initialCoord.z);

        Position._set(initialEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
        ReversePosition._set(finalCoord.x, finalCoord.y, finalCoord.z, initialEntityId);
      }
    }

    return (finalEntityIds, finalCoords, gravityApplies);
  }

  function checkMovePath(
    bytes32 playerEntityId,
    VoxelCoord memory playerCoord,
    VoxelCoord[] memory newCoords
  )
    public
    view
    returns (bytes32[] memory finalEntityIds, VoxelCoord[] memory finalCoords, bool gravityApplies, uint256 numFalls)
  {
    VoxelCoord memory oldCoord = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z);
    ObjectTypeSchemaData memory schemaData = ObjectTypeSchema._get(PlayerObjectID);

    uint256 numJumps = 0;
    uint256 numGlides = 0;
    for (uint256 i = 0; i < newCoords.length; i++) {
      VoxelCoord memory newCoord = newCoords[i];
      (finalEntityIds, finalCoords, gravityApplies) = checkMove(playerEntityId, oldCoord, newCoord, schemaData);
      if (gravityApplies) {
        if (oldCoord.y < newCoord.y) {
          numJumps++;
          require(numJumps <= 3, "MoveSystem: cannot jump more than 3 blocks");
        } else if (oldCoord.y > newCoord.y) {
          // then we are falling, so should be fine
          numFalls++;
          numGlides = 0;
        } else {
          // we are gliding
          numGlides++;
          require(numGlides <= 10, "MoveSystem: cannot glide more than 10 blocks");
        }
      } else {
        numJumps = 0;
        numGlides = 0;
      }
      oldCoord = VoxelCoord(newCoord.x, newCoord.y, newCoord.z);
    }

    return (finalEntityIds, finalCoords, gravityApplies, numFalls);
  }

  function moveInto(bytes32 playerEntityId, VoxelCoord memory newCoord) internal view returns (bytes32) {
    bytes32 newEntityId = ReversePosition._get(newCoord.x, newCoord.y, newCoord.z);
    if (newEntityId == bytes32(0)) {
      // Check terrain block type
      uint8 terrainObjectTypeId = getTerrainObjectTypeId(newCoord);
      require(
        terrainObjectTypeId == AirObjectID || terrainObjectTypeId == WaterObjectID,
        string.concat(
          "MoveSystem: cannot move to (",
          Strings.toString(newCoord.x),
          ", ",
          Strings.toString(newCoord.y),
          ", ",
          Strings.toString(newCoord.z),
          ")",
          " with terrain object type ",
          Strings.toString(terrainObjectTypeId)
        )
      );
    } else {
      // If the entity we're moving into is this player, then it's fine as
      // the player will be moved from the old position to the new position
      if (playerEntityId != newEntityId) {
        uint8 currentObjectTypeId = ObjectType._get(newEntityId);
        require(
          currentObjectTypeId == AirObjectID,
          string.concat(
            "MoveSystem: cannot move to (",
            Strings.toString(newCoord.x),
            ", ",
            Strings.toString(newCoord.y),
            ", ",
            Strings.toString(newCoord.z),
            ")",
            " with object type ",
            Strings.toString(currentObjectTypeId)
          )
        );
      }
    }

    return newEntityId;
  }

  function checkMove(
    bytes32 playerEntityId,
    VoxelCoord memory oldCoord,
    VoxelCoord memory newCoord,
    ObjectTypeSchemaData memory schemaData
  ) internal view returns (bytes32[] memory, VoxelCoord[] memory, bool) {
    require(inWorldBorder(newCoord), "MoveSystem: cannot move outside world border");
    require(
      inSurroundingCube(oldCoord, 1, newCoord),
      string.concat(
        "MoveSystem: new coord (",
        Strings.toString(newCoord.x),
        ", ",
        Strings.toString(newCoord.y),
        ", ",
        Strings.toString(newCoord.z),
        ") is not in surrounding cube of old coord (",
        Strings.toString(oldCoord.x),
        ", ",
        Strings.toString(oldCoord.y),
        ", ",
        Strings.toString(oldCoord.z),
        ")"
      )
    );

    bytes32[] memory newEntityIds = new bytes32[](schemaData.relativePositionsX.length + 1);
    bytes32 newEntityId = moveInto(playerEntityId, newCoord);
    newEntityIds[0] = newEntityId;
    VoxelCoord[] memory newCoords = new VoxelCoord[](schemaData.relativePositionsX.length + 1);
    newCoords[0] = newCoord;

    for (uint256 i = 0; i < schemaData.relativePositionsX.length; i++) {
      VoxelCoord memory relativeCoord = VoxelCoord(
        newCoord.x + schemaData.relativePositionsX[i],
        newCoord.y + schemaData.relativePositionsY[i],
        newCoord.z + schemaData.relativePositionsZ[i]
      );
      newEntityIds[i + 1] = moveInto(playerEntityId, relativeCoord);
      newCoords[i + 1] = relativeCoord;
    }

    // require(!gravityApplies(newCoord), "MoveSystem: cannot move player with gravity");

    return (newEntityIds, newCoords, gravityApplies(newCoord));
  }
}
