// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { coordToShardCoordIgnoreY } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

import { Stamina } from "../../codegen/tables/Stamina.sol";
import { Chip, ChipData } from "../../codegen/tables/Chip.sol";
import { ShardFields } from "../../codegen/tables/ShardFields.sol";
import { ForceField, ForceFieldData } from "../../codegen/tables/ForceField.sol";

import { MAX_PLAYER_STAMINA, FORCE_FIELD_DIM, FORCE_FIELD_SHARD_DIM } from "../../Constants.sol";
import { ForceFieldObjectID } from "../../ObjectTypeIds.sol";
import { updateChipBatteryLevel } from "../../utils/ChipUtils.sol";
import { getForceField } from "../../utils/ForceFieldUtils.sol";

import { IChip } from "../../prototypes/IChip.sol";

contract ForceFieldSystem is System {
  function requireBuildAllowed(
    bytes32 playerEntityId,
    bytes32 entityId,
    uint8 objectTypeId,
    VoxelCoord memory coord,
    bytes memory extraData
  ) public payable {
    bytes32 forceFieldEntityId = getForceField(coord);
    if (objectTypeId == ForceFieldObjectID) {
      require(forceFieldEntityId == bytes32(0), "BuildSystem: Force field overlaps with another force field");
      setupForceField(entityId, coord);
    }

    if (forceFieldEntityId != bytes32(0)) {
      address chipAddress = Chip._getChipAddress(forceFieldEntityId);
      if (chipAddress != address(0)) {
        updateChipBatteryLevel(forceFieldEntityId);

        // Forward any ether sent with the transaction to the hook
        // Don't safe call here as we want to revert if the chip doesn't allow the build
        bool buildAllowed = IChip(chipAddress).onBuild{ value: _msgValue() }(
          forceFieldEntityId,
          playerEntityId,
          objectTypeId,
          coord,
          extraData
        );
        require(buildAllowed, "Player not authorized by chip to build here");
      }
    }
  }

  function requireMineAllowed(
    bytes32 playerEntityId,
    uint32 equippedToolDamage,
    bytes32 entityId,
    uint8 objectTypeId,
    VoxelCoord memory coord,
    bytes memory extraData
  ) public payable {
    bytes32 forceFieldEntityId = getForceField(coord);
    if (forceFieldEntityId != bytes32(0)) {
      address chipAddress = Chip._getChipAddress(forceFieldEntityId);
      if (chipAddress != address(0)) {
        updateChipBatteryLevel(forceFieldEntityId);

        // Forward any ether sent with the transaction to the hook
        // Don't safe call here as we want to revert if the chip doesn't allow the mine
        bool mineAllowed = IChip(chipAddress).onMine{ value: _msgValue() }(
          forceFieldEntityId,
          playerEntityId,
          objectTypeId,
          coord,
          extraData
        );
        if (!mineAllowed) {
          // Apply an additional stamina cost for mining inside of a force field
          // Scale the stamina required by the chip's battery level
          uint256 staminaRequired = (Chip._getBatteryLevel(forceFieldEntityId) * 1000) / equippedToolDamage;
          uint32 currentStamina = Stamina._getStamina(playerEntityId);
          require(
            staminaRequired <= MAX_PLAYER_STAMINA,
            "MineSystem: mining difficulty too high due to force field. Try a stronger tool."
          );
          uint32 useStamina = staminaRequired == 0 ? 1 : uint32(staminaRequired);
          require(currentStamina >= useStamina, "MineSystem: not enough stamina due to force field");
          Stamina._setStamina(playerEntityId, currentStamina - useStamina);
        }
      }
    }

    if (objectTypeId == ForceFieldObjectID) {
      destroyForceField(entityId, coord);
    }
  }

  function setupForceField(bytes32 forceFieldEntityId, VoxelCoord memory coord) internal {
    // NOTE: This assumes FORCE_FIELD_DIM < FORCE_FIELD_SHARD_DIM

    // This coord will be the center of the force field
    int16 halfDim = FORCE_FIELD_DIM / 2;
    int16 fieldLowX = coord.x - halfDim;
    int16 fieldHighX = coord.x + halfDim + 1;
    int16 fieldLowZ = coord.z - halfDim;
    int16 fieldHighZ = coord.z + halfDim + 1;

    // Check the 4 corners of the force field to make sure they dont overlap with another force field
    VoxelCoord[4] memory fieldCorners = [
      VoxelCoord(fieldLowX, coord.y, fieldLowZ),
      VoxelCoord(fieldLowX, coord.y, fieldHighZ),
      VoxelCoord(fieldHighX, coord.y, fieldLowZ),
      VoxelCoord(fieldHighX, coord.y, fieldHighZ)
    ];

    // Use an array to track pushed shard coordinates
    bytes32[] memory pushedShardCoods = new bytes32[](fieldCorners.length);
    uint pushedShardCoodsLength = 0;

    for (uint i = 0; i < fieldCorners.length; i++) {
      VoxelCoord memory cornerShardCoord = coordToShardCoordIgnoreY(fieldCorners[i], FORCE_FIELD_SHARD_DIM);
      require(
        getForceField(fieldCorners[i], cornerShardCoord) == bytes32(0),
        "Force field overlaps with another force field"
      );
      bytes32 cornerShardCoordHash = keccak256(
        abi.encodePacked(cornerShardCoord.x, cornerShardCoord.y, cornerShardCoord.z)
      );
      if (_isPushed(pushedShardCoods, pushedShardCoodsLength, cornerShardCoordHash)) {
        continue;
      }
      pushedShardCoods[pushedShardCoodsLength] = cornerShardCoordHash;
      pushedShardCoodsLength++;
      ShardFields._push(cornerShardCoord.x, cornerShardCoord.z, forceFieldEntityId);
    }

    ForceField._set(
      forceFieldEntityId,
      ForceFieldData({ fieldLowX: fieldLowX, fieldHighX: fieldHighX, fieldLowZ: fieldLowZ, fieldHighZ: fieldHighZ })
    );
  }

  function destroyForceField(bytes32 forceFieldEntityId, VoxelCoord memory coord) internal {
    ForceFieldData memory forceFieldData = ForceField._get(forceFieldEntityId);

    // Check the 4 corners of the force field to make sure they dont overlap with another force field
    VoxelCoord[4] memory fieldCorners = [
      VoxelCoord(forceFieldData.fieldLowX, coord.y, forceFieldData.fieldLowZ),
      VoxelCoord(forceFieldData.fieldLowX, coord.y, forceFieldData.fieldHighZ),
      VoxelCoord(forceFieldData.fieldHighX, coord.y, forceFieldData.fieldLowZ),
      VoxelCoord(forceFieldData.fieldHighX, coord.y, forceFieldData.fieldHighZ)
    ];

    // Use an array to track pushed shard coordinates
    bytes32[] memory pushedShardCoods = new bytes32[](fieldCorners.length);
    uint pushedShardCoodsLength = 0;

    for (uint i = 0; i < fieldCorners.length; i++) {
      VoxelCoord memory cornerShardCoord = coordToShardCoordIgnoreY(fieldCorners[i], FORCE_FIELD_SHARD_DIM);
      bytes32 cornerShardCoordHash = keccak256(
        abi.encodePacked(cornerShardCoord.x, cornerShardCoord.y, cornerShardCoord.z)
      );
      if (_isPushed(pushedShardCoods, pushedShardCoodsLength, cornerShardCoordHash)) {
        continue;
      }
      pushedShardCoods[pushedShardCoodsLength] = cornerShardCoordHash;
      pushedShardCoodsLength++;
      bytes32[] memory forceFieldEntityIds = ShardFields._get(cornerShardCoord.x, cornerShardCoord.z);
      bytes32[] memory newForceFieldEntityIds = new bytes32[](forceFieldEntityIds.length - 1);
      uint newForceFieldEntityIdsLength = 0;
      for (uint j = 0; j < forceFieldEntityIds.length; j++) {
        if (forceFieldEntityIds[j] != forceFieldEntityId) {
          newForceFieldEntityIds[newForceFieldEntityIdsLength] = forceFieldEntityIds[j];
          newForceFieldEntityIdsLength++;
        }
      }
      ShardFields._set(cornerShardCoord.x, cornerShardCoord.z, newForceFieldEntityIds);
    }

    ForceField._deleteRecord(forceFieldEntityId);
  }

  function _isPushed(
    bytes32[] memory coordHashes,
    uint coordHashesLength,
    bytes32 coordHash
  ) internal pure returns (bool) {
    for (uint i = 0; i < coordHashesLength; i++) {
      if (coordHashes[i] == coordHash) {
        return true;
      }
    }
    return false;
  }
}
