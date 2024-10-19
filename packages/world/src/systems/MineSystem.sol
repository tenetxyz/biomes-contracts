// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { callInternalSystem } from "@biomesaw/utils/src/CallUtils.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Chip, ChipData } from "../codegen/tables/Chip.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { MAX_PLAYER_STAMINA, MAX_PLAYER_INFLUENCE_HALF_WIDTH, PLAYER_HAND_DAMAGE } from "../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { callGravity, inWorldBorder, inSpawnArea, getTerrainObjectTypeId, getUniqueEntity } from "../Utils.sol";
import { addToInventoryCount, useEquipped } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { mintXP } from "../utils/XPUtils.sol";

import { IForceFieldSystem } from "../codegen/world/IForceFieldSystem.sol";

contract MineSystem is System {
  function mine(VoxelCoord memory coord, bytes memory extraData) public payable {
    uint256 initialGas = gasleft();

    require(inWorldBorder(coord), "MineSystem: cannot mine outside world border");
    require(!inSpawnArea(coord), "MineSystem: cannot mine at spawn area");

    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, coord);

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
      ChipData memory chipData = Chip._get(entityId);
      require(chipData.batteryLevel == 0, "MineSystem: chip battery level is not 0");
      if (chipData.chipAddress != address(0)) {
        Chip._deleteRecord(entityId);
      }
    }
    require(ObjectTypeMetadata._getIsBlock(mineObjectTypeId), "MineSystem: object type is not a block");
    require(mineObjectTypeId != AirObjectID, "MineSystem: cannot mine air");
    require(mineObjectTypeId != WaterObjectID, "MineSystem: cannot mine water");

    bytes32 equippedEntityId = Equipped._get(playerEntityId);
    uint32 equippedToolDamage = PLAYER_HAND_DAMAGE;
    if (equippedEntityId != bytes32(0)) {
      equippedToolDamage = ObjectTypeMetadata._getDamage(ObjectType._get(equippedEntityId));
    }
    {
      uint256 miningDifficulty = uint256(ObjectTypeMetadata._getMiningDifficulty(mineObjectTypeId));
      uint32 currentStamina = Stamina._getStamina(playerEntityId);
      uint256 staminaRequired = (miningDifficulty * 1000) / (equippedToolDamage);
      require(staminaRequired <= MAX_PLAYER_STAMINA, "MineSystem: mining difficulty too high. Try a stronger tool.");
      uint32 useStamina = staminaRequired == 0 ? 1 : uint32(staminaRequired);
      require(currentStamina >= useStamina, "MineSystem: not enough stamina");
      uint32 newStamina = currentStamina - useStamina;
      Stamina._setStamina(playerEntityId, newStamina);

      useEquipped(playerEntityId, equippedEntityId);
    }

    ObjectType._set(entityId, AirObjectID);
    addToInventoryCount(playerEntityId, PlayerObjectID, mineObjectTypeId, 1);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Mine,
        entityId: entityId,
        objectTypeId: mineObjectTypeId,
        coordX: coord.x,
        coordY: coord.y,
        coordZ: coord.z,
        amount: 1
      })
    );

    mintXP(playerEntityId, initialGas, 1);

    callInternalSystem(
      abi.encodeCall(
        IForceFieldSystem.requireMineAllowed,
        (playerEntityId, equippedToolDamage, entityId, mineObjectTypeId, coord, extraData)
      )
    );

    // Apply gravity
    {
      VoxelCoord memory aboveCoord = VoxelCoord(coord.x, coord.y + 1, coord.z);
      bytes32 aboveEntityId = ReversePosition._get(aboveCoord.x, aboveCoord.y, aboveCoord.z);
      if (aboveEntityId != bytes32(0) && ObjectType._get(aboveEntityId) == PlayerObjectID) {
        callGravity(aboveEntityId, aboveCoord);
      }
    }
  }

  function mine(VoxelCoord memory coord) public payable {
    mine(coord, new bytes(0));
  }
}
