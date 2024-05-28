// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Health, HealthData } from "../codegen/tables/Health.sol";
import { Stamina, StaminaData } from "../codegen/tables/Stamina.sol";
import { ExperiencePoints } from "../codegen/tables/ExperiencePoints.sol";
import { WorldMetadata } from "../codegen/tables/WorldMetadata.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, TIME_BEFORE_INCREASE_STAMINA, STAMINA_INCREASE_RATE, WATER_STAMINA_INCREASE_RATE, TIME_BEFORE_INCREASE_HEALTH, HEALTH_INCREASE_RATE } from "../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID, ChestObjectID } from "../ObjectTypeIds.sol";
import { getTerrainObjectTypeId } from "../Utils.sol";

function calculateXPToBurnFromLogout(bytes32 playerEntityId) view returns (uint256) {
  uint256 timeSinceLogoff = block.timestamp - PlayerActivity._get(playerEntityId);
  uint256 xpBurn = timeSinceLogoff / 60;
  return xpBurn;
}

function mintXP(bytes32 playerEntityId, uint256 xpToMint) {
  uint256 currentXP = ExperiencePoints._get(playerEntityId);
  ExperiencePoints._set(playerEntityId, currentXP + xpToMint);
  WorldMetadata._setXpSupply(WorldMetadata._getXpSupply() + xpToMint);
}

function burnXP(bytes32 playerEntityId, uint256 xpToBurn) returns (uint256) {
  uint256 currentXP = ExperiencePoints._get(playerEntityId);
  require(currentXP >= xpToBurn, "player does not have enough xp");
  uint256 newXP = currentXP - xpToBurn;
  ExperiencePoints._set(playerEntityId, newXP);
  WorldMetadata._setXpSupply(WorldMetadata._getXpSupply() - xpToBurn);
  return newXP;
}

function safeBurnXP(bytes32 playerEntityId, uint256 xpToBurn) returns (uint256) {
  uint256 currentXP = ExperiencePoints._get(playerEntityId);
  if (currentXP < xpToBurn) {
    xpToBurn = currentXP;
  }
  uint256 newXP = currentXP - xpToBurn;
  ExperiencePoints._set(playerEntityId, newXP);
  WorldMetadata._setXpSupply(WorldMetadata._getXpSupply() - xpToBurn);
  return newXP;
}
