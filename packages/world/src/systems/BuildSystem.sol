// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Player } from "../codegen/tables/Player.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { InventoryCount } from "../codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../codegen/tables/InventoryObjects.sol";
import { ReverseInventoryTool } from "../codegen/tables/ReverseInventoryTool.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { Chip, ChipData } from "../codegen/tables/Chip.sol";
import { ShardFields } from "../codegen/tables/ShardFields.sol";
import { ForceField, ForceFieldData } from "../codegen/tables/ForceField.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_BUILD_MINE_HALF_WIDTH, FORCE_FIELD_DIM, FORCE_FIELD_SHARD_DIM } from "../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID, ForceFieldObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord, inSpawnArea, inWorldBorder, getTerrainObjectTypeId, getUniqueEntity } from "../Utils.sol";
import { removeFromInventoryCount } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina } from "../utils/PlayerUtils.sol";
import { inSurroundingCube, coordToShardCoordIgnoreY } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { updateChipBatteryLevel } from "../utils/ChipUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { IChip } from "../prototypes/IChip.sol";

contract BuildSystem is System {
  function build(uint8 objectTypeId, VoxelCoord memory coord, bytes memory extraData) public payable returns (bytes32) {
    require(inWorldBorder(coord), "BuildSystem: cannot build outside world border");
    require(!inSpawnArea(coord), "BuildSystem: cannot build at spawn area");

    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "BuildSystem: player does not exist");
    require(ObjectTypeMetadata._getIsBlock(objectTypeId), "BuildSystem: object type is not a block");
    require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "BuildSystem: player isn't logged in");
    VoxelCoord memory playerCoord = positionDataToVoxelCoord(Position._get(playerEntityId));
    require(
      inSurroundingCube(playerCoord, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, coord),
      "BuildSystem: player is too far from the block"
    );

    regenHealth(playerEntityId);
    regenStamina(playerEntityId, playerCoord);

    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    if (entityId == bytes32(0)) {
      // Check terrain block type
      uint8 terrainObjectTypeId = getTerrainObjectTypeId(coord);
      require(terrainObjectTypeId != WaterObjectID, "BuildSystem: cannot build on water block");
      require(terrainObjectTypeId == AirObjectID, "BuildSystem: cannot build on terrain non-air block");

      entityId = getUniqueEntity();
      Position._set(entityId, coord.x, coord.y, coord.z);
      ReversePosition._set(coord.x, coord.y, coord.z, entityId);
    } else {
      require(ObjectType._get(entityId) == AirObjectID, "BuildSystem: cannot build on non-air block");
      require(getTerrainObjectTypeId(coord) != WaterObjectID, "BuildSystem: cannot build on water block");
      require(
        InventoryObjects._lengthObjectTypeIds(entityId) == 0,
        "BuildSystem: Cannot build where there are dropped objects"
      );
    }

    ObjectType._set(entityId, objectTypeId);
    removeFromInventoryCount(playerEntityId, objectTypeId, 1);

    PlayerActivity._set(playerEntityId, block.timestamp);

    bytes32 forceFieldEntityId = getForceField(coord);
    if (objectTypeId == ForceFieldObjectID) {
      require(forceFieldEntityId == bytes32(0), "BuildSystem: Force field overlaps with another force field");
      setupForceField(entityId, coord);
    }

    // Note: we call this after the build state has been updated, to prevent re-entrancy attacks
    requireAllowed(forceFieldEntityId, playerEntityId, objectTypeId, coord, extraData);

    return entityId;
  }

  function setupForceField(bytes32 entityId, VoxelCoord memory coord) internal {
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
    bytes32[] memory pushedShardCoods = new bytes32[](4);
    uint pushedShardCoodsLength = 0;

    for (uint i = 0; i < fieldCorners.length; i++) {
      VoxelCoord memory cornerShardCoord = coordToShardCoordIgnoreY(fieldCorners[i], FORCE_FIELD_SHARD_DIM);
      require(
        getForceField(fieldCorners[i], cornerShardCoord) == bytes32(0),
        "BuildSystem: Force field overlaps with another force field"
      );
      bytes32 cornerShardCoordHash = keccak256(
        abi.encodePacked(cornerShardCoord.x, cornerShardCoord.y, cornerShardCoord.z)
      );
      if (_isPushed(pushedShardCoods, pushedShardCoodsLength, cornerShardCoordHash)) {
        continue;
      }
      pushedShardCoods[pushedShardCoodsLength] = cornerShardCoordHash;
      pushedShardCoodsLength++;
      ShardFields._push(cornerShardCoord.x, cornerShardCoord.z, entityId);
    }

    ForceField._set(
      entityId,
      ForceFieldData({ fieldLowX: fieldLowX, fieldHighX: fieldHighX, fieldLowZ: fieldLowZ, fieldHighZ: fieldHighZ })
    );
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

  function requireAllowed(
    bytes32 forceFieldEntityId,
    bytes32 playerEntityId,
    uint8 objectTypeId,
    VoxelCoord memory coord,
    bytes memory extraData
  ) internal {
    if (forceFieldEntityId != bytes32(0)) {
      address chipAddress = Chip._getChipAddress(forceFieldEntityId);
      if (chipAddress != address(0)) {
        updateChipBatteryLevel(forceFieldEntityId);

        // Forward any ether sent with the transaction to the hook
        // Don't safe call here as we want to revert if the chip doesn't allow the build
        bool buildAllowed = IChip(chipAddress).onBuild{ value: msg.value }(
          playerEntityId,
          objectTypeId,
          coord,
          extraData
        );
        require(buildAllowed, "BuildSystem: Player not authorized by chip to build here");
      } else {
        revert("BuildSystem: Cannot build in force field without chip");
      }
    }
  }
}
