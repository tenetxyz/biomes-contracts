// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { inSurroundingCube, voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { callInternalSystem } from "@biomesaw/utils/src/CallUtils.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";
import { ObjectTypeSchema, ObjectTypeSchemaData } from "../codegen/tables/ObjectTypeSchema.sol";

import { PLAYER_MASS, GRAVITY_STAMINA_COST, MAX_PLAYER_STAMINA } from "../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { callGravity, gravityApplies, inWorldBorder, getTerrainObjectTypeId, getUniqueEntity, callMintXP } from "../Utils.sol";
import { transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { requireValidPlayer } from "../utils/PlayerUtils.sol";

import { IMoveHelperSystem } from "../codegen/world/IMoveHelperSystem.sol";

contract MoveSystem is System {
  function move(VoxelCoord[] memory newCoords) public {
    uint256 initialGas = gasleft();

    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    // no-ops
    if (newCoords.length == 0) {
      return;
    } else if (newCoords.length == 1 && voxelCoordsAreEqual(playerCoord, newCoords[0])) {
      return;
    }

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

    bytes memory moveResult = callInternalSystem(
      abi.encodeCall(IMoveHelperSystem.checkMovePath, (playerEntityId, playerCoord, newCoords))
    );
    (bytes32[] memory finalEntityIds, VoxelCoord[] memory finalCoords, bool gravityApplies) = abi.decode(
      moveResult,
      (bytes32[], VoxelCoord[], bool)
    );
    require(
      finalEntityIds.length == initialEntityIds.length && finalCoords.length == initialCoords.length,
      "MoveSystem: final entity ids length mismatch"
    );

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

    if (gravityApplies) {
      callGravity(playerEntityId, finalCoords[0]);
    }

    {
      VoxelCoord memory aboveCoord = VoxelCoord(playerCoord.x, playerCoord.y + 2, playerCoord.z);
      bytes32 aboveEntityId = ReversePosition._get(aboveCoord.x, aboveCoord.y, aboveCoord.z);
      if (aboveEntityId != bytes32(0) && ObjectType._get(aboveEntityId) == PlayerObjectID) {
        callGravity(aboveEntityId, aboveCoord);
      }
    }

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Move,
        entityId: finalEntityIds[0],
        objectTypeId: PlayerObjectID,
        coordX: finalCoords[0].x,
        coordY: finalCoords[0].y,
        coordZ: finalCoords[0].z,
        amount: newCoords.length
      })
    );

    callMintXP(playerEntityId, initialGas, 10);
  }
}
