// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { Player } from "../codegen/tables/Player.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { Chip, ChipData } from "../codegen/tables/Chip.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_STAMINA, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, PLAYER_HAND_DAMAGE, HIT_STAMINA_COST } from "../Constants.sol";
import { positionDataToVoxelCoord, callGravity, inWorldBorder, inSpawnArea, getTerrainObjectTypeId, getUniqueEntity } from "../Utils.sol";
import { addToInventoryCount, removeFromInventoryCount, useEquipped, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina } from "../utils/PlayerUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { callInternalSystem } from "@biomesaw/utils/src/CallUtils.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID, ChestObjectID, ChipObjectID, ChipBatteryObjectID } from "../ObjectTypeIds.sol";

contract ChipSystem is System {
  function updateChipBatteryLevel(bytes32 entityId) internal returns (ChipData memory) {
    ChipData memory chipData = Chip._get(entityId);

    if (chipData.batteryLevel > 0) {
      uint256 timeDiff = block.timestamp - chipData.lastUpdatedTime;
      uint256 batteryDecay = timeDiff / 60; // 1 minute
      if (batteryDecay > chipData.batteryLevel) {
        chipData.batteryLevel = 0;
        Chip._setBatteryLevel(entityId, 0);
      } else {
        chipData.batteryLevel -= batteryDecay;
        Chip._setBatteryLevel(entityId, chipData.batteryLevel - batteryDecay);
      }
      chipData.lastUpdatedTime = block.timestamp;
      Chip._setLastUpdatedTime(entityId, block.timestamp);
    }

    return chipData;
  }

  function attachChip(bytes32 entityId, address chipAddress) public {
    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "ChipSystem: player does not exist");
    require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "ChipSystem: player isn't logged in");
    VoxelCoord memory playerCoord = positionDataToVoxelCoord(Position._get(playerEntityId));
    VoxelCoord memory coord = positionDataToVoxelCoord(Position._get(entityId));
    require(inSurroundingCube(playerCoord, 1, coord), "ChipSystem: player is too far from the object");

    regenHealth(playerEntityId);
    regenStamina(playerEntityId, playerCoord);

    uint8 objectTypeId = ObjectType._get(entityId);
    require(objectTypeId == ChestObjectID, "ChipSystem: cannot attach a chip to this object");
    require(Chip._getChipAddress(entityId) == address(0), "ChipSystem: chip already attached");
    require(chipAddress != address(0), "ChipSystem: invalid chip address");

    // TODO: Check interface of chipAddress

    removeFromInventoryCount(playerEntityId, ChipObjectID, 1);

    Chip._set(entityId, ChipData({ chipAddress: chipAddress, batteryLevel: 0, lastUpdatedTime: block.timestamp }));

    PlayerActivity._set(playerEntityId, block.timestamp);
  }

  function detachChip(bytes32 entityId) public {
    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "ChipSystem: player does not exist");
    require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "ChipSystem: player isn't logged in");
    VoxelCoord memory playerCoord = positionDataToVoxelCoord(Position._get(playerEntityId));
    VoxelCoord memory coord = positionDataToVoxelCoord(Position._get(entityId));
    require(inSurroundingCube(playerCoord, 1, coord), "ChipSystem: player is too far from the object");

    regenHealth(playerEntityId);
    regenStamina(playerEntityId, playerCoord);

    ChipData memory chipData = updateChipBatteryLevel(entityId);
    require(chipData.batteryLevel == 0, "ChipSystem: battery level is not empty");
    require(chipData.chipAddress != address(0), "ChipSystem: no chip attached");

    // TODO: notify chipAddress

    Chip._deleteRecord(entityId);

    PlayerActivity._set(playerEntityId, block.timestamp);
  }

  function powerChip(bytes32 entityId, uint16 powerAmount) public {
    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "ChipSystem: player does not exist");
    require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "ChipSystem: player isn't logged in");
    VoxelCoord memory playerCoord = positionDataToVoxelCoord(Position._get(playerEntityId));
    VoxelCoord memory coord = positionDataToVoxelCoord(Position._get(entityId));
    require(inSurroundingCube(playerCoord, 1, coord), "ChipSystem: player is too far from the object");

    regenHealth(playerEntityId);
    regenStamina(playerEntityId, playerCoord);

    ChipData memory chipData = updateChipBatteryLevel(entityId);
    require(chipData.chipAddress != address(0), "ChipSystem: no chip attached");

    removeFromInventoryCount(playerEntityId, ChipBatteryObjectID, powerAmount);

    // TODO: notify chipAddress

    // TODO: Figure out how to scale powerAmount
    Chip._setBatteryLevel(entityId, chipData.batteryLevel + powerAmount);
    Chip._setLastUpdatedTime(entityId, block.timestamp);

    PlayerActivity._set(playerEntityId, block.timestamp);
  }

  function hitChip(bytes32 entityId) public {
    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "ChipSystem: player does not exist");
    require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "ChipSystem: player isn't logged in");
    VoxelCoord memory playerCoord = positionDataToVoxelCoord(Position._get(playerEntityId));
    VoxelCoord memory coord = positionDataToVoxelCoord(Position._get(entityId));
    require(inSurroundingCube(playerCoord, 1, coord), "ChipSystem: player is too far from the object");

    regenHealth(playerEntityId);
    regenStamina(playerEntityId, playerCoord);
    ChipData memory chipData = updateChipBatteryLevel(entityId);

    // TODO: notify chipAddress

    uint32 currentStamina = Stamina._getStamina(playerEntityId);
    uint16 staminaRequired = HIT_STAMINA_COST;
    require(currentStamina >= staminaRequired, "ChipSystem: player does not have enough stamina");
    Stamina._setStamina(playerEntityId, currentStamina - staminaRequired);

    uint16 receiverDamage = PLAYER_HAND_DAMAGE;
    bytes32 equippedEntityId = Equipped._get(playerEntityId);
    if (equippedEntityId != bytes32(0)) {
      receiverDamage = ObjectTypeMetadata._getDamage(ObjectType._get(equippedEntityId));
    }

    uint256 currentBatteryLevel = chipData.batteryLevel;
    uint256 newBatteryLevel = currentBatteryLevel > receiverDamage ? currentBatteryLevel - receiverDamage : 0;
    Chip._setBatteryLevel(entityId, newBatteryLevel);

    useEquipped(playerEntityId, equippedEntityId);

    PlayerActivity._set(playerEntityId, block.timestamp);
  }
}
