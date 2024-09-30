// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { PLAYER_MASS, GRAVITY_STAMINA_COST, MAX_PLAYER_STAMINA } from "../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { callGravity, gravityApplies, inWorldBorder, getTerrainObjectTypeId, getUniqueEntity } from "../Utils.sol";
import { transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { requireValidPlayer } from "../utils/PlayerUtils.sol";

contract MoveSystem is System {
  function move(VoxelCoord[] memory newCoords) public {
    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());

    VoxelCoord memory oldCoord = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z);
    bytes32 finalEntityId;
    bool gravityApplies = false;
    uint256 numJumps = 0;
    uint256 numFalls = 0;
    for (uint256 i = 0; i < newCoords.length; i++) {
      VoxelCoord memory newCoord = newCoords[i];
      if (gravityApplies) {
        VoxelCoord memory previousCoord = newCoords[i - 1];
        if (previousCoord.y < newCoord.y) {
          numJumps++;
          require(numJumps <= 3, "MoveSystem: cannot jump more than 3 blocks");
        } else {
          // TODO: if it's the same, then only allow X glides
          // then we are falling, so should be fine
          numFalls++;
        }
      } else {
        numJumps = 0;
      }
      (finalEntityId, gravityApplies) = move(playerEntityId, oldCoord, newCoord);
      oldCoord = VoxelCoord(newCoord.x, newCoord.y, newCoord.z);
    }

    // Create new entity
    if (finalEntityId == bytes32(0)) {
      finalEntityId = getUniqueEntity();
      ObjectType._set(finalEntityId, AirObjectID);
    } else {
      transferAllInventoryEntities(finalEntityId, playerEntityId, PlayerObjectID);
    }

    // Swap entity ids
    ReversePosition._set(playerCoord.x, playerCoord.y, playerCoord.z, finalEntityId);
    Position._set(finalEntityId, playerCoord.x, playerCoord.y, playerCoord.z);

    VoxelCoord memory finalCoord = newCoords[newCoords.length - 1];
    Position._set(playerEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
    ReversePosition._set(finalCoord.x, finalCoord.y, finalCoord.z, playerEntityId);

    {
      uint256 staminaRequired = (PLAYER_MASS * (newCoords.length ** 2)) / 100;
      staminaRequired += numFalls > 5 ? (GRAVITY_STAMINA_COST * numFalls) : 0;
      require(staminaRequired <= MAX_PLAYER_STAMINA, "MoveSystem: stamina required exceeds max player stamina");
      uint32 useStamina = staminaRequired == 0 ? 1 : uint32(staminaRequired);

      uint32 currentStamina = Stamina._getStamina(playerEntityId);
      require(currentStamina >= useStamina, "MoveSystem: not enough stamina");
      Stamina._setStamina(playerEntityId, currentStamina - useStamina);
    }

    if (gravityApplies) {
      callGravity(playerEntityId, finalCoord);
    }

    VoxelCoord memory aboveCoord = VoxelCoord(playerCoord.x, playerCoord.y + 1, playerCoord.z);
    bytes32 aboveEntityId = ReversePosition._get(aboveCoord.x, aboveCoord.y, aboveCoord.z);
    if (aboveEntityId != bytes32(0) && ObjectType._get(aboveEntityId) == PlayerObjectID) {
      callGravity(aboveEntityId, aboveCoord);
    }

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Move,
        entityId: finalEntityId,
        objectTypeId: PlayerObjectID,
        coordX: finalCoord.x,
        coordY: finalCoord.y,
        coordZ: finalCoord.z,
        amount: newCoords.length
      })
    );
  }

  function move(
    bytes32 playerEntityId,
    VoxelCoord memory oldCoord,
    VoxelCoord memory newCoord
  ) internal returns (bytes32, bool) {
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

    // require(!gravityApplies(newCoord), "MoveSystem: cannot move player with gravity");

    return (newEntityId, gravityApplies(newCoord));
  }
}
