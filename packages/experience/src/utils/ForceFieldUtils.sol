// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";
import { OptionalSystemHooks } from "@latticexyz/world/src/codegen/tables/OptionalSystemHooks.sol";
import { UserDelegationControl } from "@latticexyz/world/src/codegen/tables/UserDelegationControl.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { BEFORE_CALL_SYSTEM, AFTER_CALL_SYSTEM, ALL } from "@latticexyz/world/src/systemHookTypes.sol";
import { Hook } from "@latticexyz/store/src/Hook.sol";
import { Delegation } from "@latticexyz/world/src/Delegation.sol";

import { IWorld } from "@biomesaw/world/src/codegen/world/IWorld.sol";
import { ObjectTypeMetadata } from "@biomesaw/world/src/codegen/tables/ObjectTypeMetadata.sol";
import { Player } from "@biomesaw/world/src/codegen/tables/Player.sol";
import { ReversePlayer } from "@biomesaw/world/src/codegen/tables/ReversePlayer.sol";
import { PlayerMetadata } from "@biomesaw/world/src/codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "@biomesaw/world/src/codegen/tables/ObjectType.sol";
import { Position } from "@biomesaw/world/src/codegen/tables/Position.sol";
import { ReversePosition } from "@biomesaw/world/src/codegen/tables/ReversePosition.sol";
import { Equipped } from "@biomesaw/world/src/codegen/tables/Equipped.sol";
import { Health, HealthData } from "@biomesaw/world/src/codegen/tables/Health.sol";
import { Stamina, StaminaData } from "@biomesaw/world/src/codegen/tables/Stamina.sol";
import { InventoryObjects } from "@biomesaw/world/src/codegen/tables/InventoryObjects.sol";
import { InventoryTool } from "@biomesaw/world/src/codegen/tables/InventoryTool.sol";
import { ReverseInventoryTool } from "@biomesaw/world/src/codegen/tables/ReverseInventoryTool.sol";
import { InventorySlots } from "@biomesaw/world/src/codegen/tables/InventorySlots.sol";
import { InventoryCount } from "@biomesaw/world/src/codegen/tables/InventoryCount.sol";
import { Equipped } from "@biomesaw/world/src/codegen/tables/Equipped.sol";
import { ItemMetadata } from "@biomesaw/world/src/codegen/tables/ItemMetadata.sol";
import { Recipes, RecipesData } from "@biomesaw/world/src/codegen/tables/Recipes.sol";
import { ShardField } from "@biomesaw/world/src/codegen/tables/ShardField.sol";
import { Chip, ChipData } from "@biomesaw/world/src/codegen/tables/Chip.sol";

import { ForceFieldApprovals } from "../codegen/tables/ForceFieldApprovals.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { coordToShardCoord } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { positionDataToVoxelCoord } from "@biomesaw/world/src/Utils.sol";
import { FORCE_FIELD_SHARD_DIM, TIME_BEFORE_DECREASE_BATTERY_LEVEL } from "@biomesaw/world/src/Constants.sol";

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { getPosition } from "./EntityUtils.sol";

function getForceField(bytes32 entityId) view returns (bytes32) {
  VoxelCoord memory coord = getPosition(entityId);
  VoxelCoord memory shardCoord = coordToShardCoord(coord, FORCE_FIELD_SHARD_DIM);
  return ShardField.get(shardCoord.x, shardCoord.y, shardCoord.z);
}

function isApprovedPlayer(bytes32 forceFieldEntityId, address player) view returns (bool) {
  address[] memory approvedPlayers = ForceFieldApprovals.getPlayers(forceFieldEntityId);
  for (uint256 i = 0; i < approvedPlayers.length; i++) {
    if (approvedPlayers[i] == player) {
      return true;
    }
  }

  return false;
}

function hasApprovedNft(bytes32 forceFieldEntityId, address player) view returns (bool) {
  address[] memory approvedNfts = ForceFieldApprovals.getNfts(forceFieldEntityId);
  for (uint256 i = 0; i < approvedNfts.length; i++) {
    if (IERC721(approvedNfts[i]).balanceOf(player) > 0) {
      return true;
    }
  }

  return false;
}

function isApproved(bytes32 forceFieldEntityId, address player) view returns (bool) {
  return isApprovedPlayer(forceFieldEntityId, player) || hasApprovedNft(forceFieldEntityId, player);
}

function getLatestChipData(bytes32 entityId) view returns (ChipData memory) {
  ChipData memory chipData = Chip.get(entityId);

  if (chipData.batteryLevel > 0) {
    // Calculate how much time has passed since last update
    uint256 timeSinceLastUpdate = block.timestamp - chipData.lastUpdatedTime;
    if (timeSinceLastUpdate <= TIME_BEFORE_DECREASE_BATTERY_LEVEL) {
      return chipData;
    }

    chipData.batteryLevel = chipData.batteryLevel > timeSinceLastUpdate
      ? chipData.batteryLevel - timeSinceLastUpdate
      : 0;
  }

  return chipData;
}
