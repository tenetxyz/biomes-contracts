// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord, Rotation } from "@biomesaw/utils/src/Types.sol";
import { inSurroundingCube, voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { callInternalSystem } from "@biomesaw/utils/src/CallUtils.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { ObjectTypeSchema, ObjectTypeSchemaData } from "../codegen/tables/ObjectTypeSchema.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Position } from "../codegen/tables/Position.sol";
import { Orientation, OrientationData } from "../codegen/tables/Orientation.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Chip, ChipData } from "../codegen/tables/Chip.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { MAX_PLAYER_STAMINA, MAX_PLAYER_INFLUENCE_HALF_WIDTH, PLAYER_HAND_DAMAGE } from "../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { callGravity, inWorldBorder, inSpawnArea, getTerrainObjectTypeId, getUniqueEntity, callMintXP, positionDataToVoxelCoord } from "../Utils.sol";
import { addToInventoryCount, useEquipped } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { updateChipBatteryLevel } from "../utils/ChipUtils.sol";
import { getRelativeCoord, orientationToRotation } from "../utils/OrientationUtils.sol";

import { IForceFieldSystem } from "../codegen/world/IForceFieldSystem.sol";
import { IMineHelperSystem } from "../codegen/world/IMineHelperSystem.sol";

contract MineSystem is System {
  function mineObjectAtCoord(VoxelCoord memory coord) internal returns (bytes32, uint8) {
    require(inWorldBorder(coord), "MineSystem: cannot mine outside world border");

    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    uint8 mineObjectTypeId;
    if (entityId == bytes32(0)) {
      // Check terrain block type
      mineObjectTypeId = getTerrainObjectTypeId(coord);

      // Create new entity
      entityId = getUniqueEntity();
      Position._set(entityId, coord.x, coord.y, coord.z);
      ReversePosition._set(coord.x, coord.y, coord.z, entityId);
    } else {
      mineObjectTypeId = ObjectType._get(entityId);
      ChipData memory chipData = updateChipBatteryLevel(entityId);
      require(
        chipData.chipAddress == address(0) && chipData.batteryLevel == 0,
        "MineSystem: chip is attached to entity"
      );
    }
    require(ObjectTypeMetadata._getIsBlock(mineObjectTypeId), "MineSystem: object type is not a block");
    require(mineObjectTypeId != AirObjectID, "MineSystem: cannot mine air");
    require(mineObjectTypeId != WaterObjectID, "MineSystem: cannot mine water");

    ObjectType._set(entityId, AirObjectID);

    return (entityId, mineObjectTypeId);
  }

  function mine(VoxelCoord memory coord, bytes memory extraData) public payable {
    uint256 initialGas = gasleft();

    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, coord);

    (bytes32 baseEntityId, uint8 mineObjectTypeId) = mineObjectAtCoord(coord);
    require(BaseEntity._get(baseEntityId) == bytes32(0), "MineSystem: Mine the base block to mine this block");

    uint256 numRelativePositions = ObjectTypeSchema._lengthRelativePositionsX(mineObjectTypeId);
    VoxelCoord[] memory coords = new VoxelCoord[](numRelativePositions + 1);
    coords[0] = coord;

    OrientationData memory orientation = Orientation._get(baseEntityId);
    if (numRelativePositions > 0) {
      Rotation rotation = orientationToRotation(orientation);
      ObjectTypeSchemaData memory schemaData = ObjectTypeSchema._get(mineObjectTypeId);
      for (uint256 i = 0; i < numRelativePositions; i++) {
        VoxelCoord memory relativeCoord = getRelativeCoord(
          coord,
          rotation,
          VoxelCoord(
            schemaData.relativePositionsX[i],
            schemaData.relativePositionsY[i],
            schemaData.relativePositionsZ[i]
          )
        );
        coords[i + 1] = relativeCoord;
        (bytes32 relativeEntityId, ) = mineObjectAtCoord(relativeCoord);
        BaseEntity._deleteRecord(relativeEntityId);
      }
    }
    if (orientation.pitch != 0 || orientation.yaw != 0) {
      Orientation._deleteRecord(baseEntityId);
    }

    callInternalSystem(
      abi.encodeCall(IMineHelperSystem.onMine, (playerEntityId, baseEntityId, mineObjectTypeId, coords))
    );

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Mine,
        entityId: baseEntityId,
        objectTypeId: mineObjectTypeId,
        coordX: coord.x,
        coordY: coord.y,
        coordZ: coord.z,
        amount: 1
      })
    );

    callMintXP(playerEntityId, initialGas, 1);

    callInternalSystem(
      abi.encodeCall(
        IForceFieldSystem.requireMinesAllowed,
        (playerEntityId, baseEntityId, mineObjectTypeId, coords, extraData)
      )
    );
  }

  function mine(VoxelCoord memory coord) public payable {
    mine(coord, new bytes(0));
  }
}
