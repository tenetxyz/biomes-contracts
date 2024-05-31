// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { requireInterface } from "@latticexyz/world/src/requireInterface.sol";

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
import { ChestMetadata, ChestMetadataData } from "../codegen/tables/ChestMetadata.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_BUILD_MINE_HALF_WIDTH } from "../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID, ReinforcedChestObjectID, BedrockChestObjectID, BedrockObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord, inSpawnArea, inWorldBorder, getTerrainObjectTypeId, getUniqueEntity } from "../Utils.sol";
import { removeFromInventoryCount } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina } from "../utils/PlayerUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { isReinforcedLumber } from "../utils/ObjectTypeUtils.sol";
import { IChestTransferHook } from "../prototypes/IChestTransferHook.sol";

contract ChestSystem is System {
  function strengthenChest(
    bytes32 chestEntityId,
    uint8 strengthenObjectTypeId,
    uint16 strengthenObjectTypeAmount
  ) public {
    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "ChestSystem: player does not exist");
    require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "ChestSystem: player isn't logged in");
    ChestMetadataData memory chestMetadata = ChestMetadata._get(chestEntityId);
    require(chestMetadata.owner == _msgSender(), "ChestSystem: player does not own chest");
    VoxelCoord memory playerCoord = positionDataToVoxelCoord(Position._get(playerEntityId));
    VoxelCoord memory chestCoord = positionDataToVoxelCoord(Position._get(chestEntityId));
    require(
      inSurroundingCube(playerCoord, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, chestCoord),
      "ChestSystem: player is too far from the chest"
    );
    uint8 chestObjectTypeId = ObjectType._get(chestEntityId);
    if (chestObjectTypeId == ReinforcedChestObjectID) {
      require(isReinforcedLumber(strengthenObjectTypeId), "ChestSystem: invalid strengthen object type");
    } else if (chestObjectTypeId == BedrockChestObjectID) {
      require(strengthenObjectTypeId == BedrockObjectID, "ChestSystem: invalid strengthen object type");
    } else {
      revert("ChestSystem: invalid chest object type");
    }

    removeFromInventoryCount(playerEntityId, strengthenObjectTypeId, strengthenObjectTypeAmount);

    chestMetadata.strength +=
      uint256(ObjectTypeMetadata._getMiningDifficulty(strengthenObjectTypeId)) *
      strengthenObjectTypeAmount;

    bool found = false;
    for (uint i = 0; i < chestMetadata.strengthenObjectTypeIds.length; i++) {
      if (chestMetadata.strengthenObjectTypeIds[i] == strengthenObjectTypeId) {
        found = true;
        chestMetadata.strengthenObjectTypeAmounts[i] += strengthenObjectTypeAmount;
        break;
      }
    }

    if (!found) {
      uint8[] memory newStrengthenObjectTypeIds = new uint8[](chestMetadata.strengthenObjectTypeIds.length + 1);
      uint16[] memory newStrengthenObjectTypeAmounts = new uint16[](
        chestMetadata.strengthenObjectTypeAmounts.length + 1
      );
      for (uint i = 0; i < chestMetadata.strengthenObjectTypeIds.length; i++) {
        newStrengthenObjectTypeIds[i] = chestMetadata.strengthenObjectTypeIds[i];
        newStrengthenObjectTypeAmounts[i] = chestMetadata.strengthenObjectTypeAmounts[i];
      }
      newStrengthenObjectTypeIds[chestMetadata.strengthenObjectTypeIds.length] = strengthenObjectTypeId;
      newStrengthenObjectTypeAmounts[chestMetadata.strengthenObjectTypeAmounts.length] = strengthenObjectTypeAmount;
    }

    ChestMetadata._set(chestEntityId, chestMetadata);
  }

  function setChestTransferHook(bytes32 chestEntityId, address hookAddress) public {
    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "ChestSystem: player does not exist");
    require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "ChestSystem: player isn't logged in");
    // Note: we don't need to check the object type since if it's a chest type, it will have a chest metadata
    require(ChestMetadata._getOwner(chestEntityId) == _msgSender(), "ChestSystem: player does not own chest");
    VoxelCoord memory playerCoord = positionDataToVoxelCoord(Position._get(playerEntityId));
    VoxelCoord memory chestCoord = positionDataToVoxelCoord(Position._get(chestEntityId));
    require(
      inSurroundingCube(playerCoord, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, chestCoord),
      "ChestSystem: player is too far from the chest"
    );
    require(
      ChestMetadata._getOnTransferHook(chestEntityId) == address(0),
      "ChestSystem: chest already has a transfer hook"
    );
    requireInterface(hookAddress, type(IChestTransferHook).interfaceId);
    ChestMetadata._setOnTransferHook(chestEntityId, hookAddress);
  }
}
