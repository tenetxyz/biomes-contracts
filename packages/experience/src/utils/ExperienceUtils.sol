// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";

import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { CountdownData } from "../codegen/tables/Countdown.sol";
import { ExperienceMetadataData } from "../codegen/tables/ExperienceMetadata.sol";
import { ChipMetadataData } from "../codegen/tables/ChipMetadata.sol";

import { Area } from "./AreaUtils.sol";
import { Build, BuildWithPos } from "./BuildUtils.sol";

function setArea(bytes32 areaId, string memory name, Area memory area) {
  IWorld(WorldContextConsumerLib._world()).experience__setArea(areaId, name, area);
}

function deleteArea(bytes32 areaId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteArea(areaId);
}

function setBuild(bytes32 buildId, string memory name, Build memory build) {
  IWorld(WorldContextConsumerLib._world()).experience__setBuild(buildId, name, build);
}

function deleteBuild(bytes32 buildId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteBuild(buildId);
}

function setBuildWithPos(bytes32 buildId, string memory name, BuildWithPos memory build) {
  IWorld(WorldContextConsumerLib._world()).experience__setBuildWithPos(buildId, name, build);
}

function deleteBuildWithPos(bytes32 buildId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteBuildWithPos(buildId);
}

function setChipAttacher(bytes32 entityId, address attacher) {
  IWorld(WorldContextConsumerLib._world()).experience__setChipAttacher(entityId, attacher);
}

function deleteChipAttacher(bytes32 entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteChipAttacher(entityId);
}

function setChipMetadata(ChipMetadataData memory metadata) {
  IWorld(WorldContextConsumerLib._world()).experience__setChipMetadata(metadata);
}

function deleteChipMetadata() {
  IWorld(WorldContextConsumerLib._world()).experience__deleteChipMetadata();
}

function setCountdown(CountdownData memory countdownData) {
  IWorld(WorldContextConsumerLib._world()).experience__setCountdown(countdownData);
}

function setCountdownEndTimestamp(uint256 countdownEndTimestamp) {
  IWorld(WorldContextConsumerLib._world()).experience__setCountdownEndTimestamp(countdownEndTimestamp);
}

function setCountdownEndBlock(uint256 countdownEndBlock) {
  IWorld(WorldContextConsumerLib._world()).experience__setCountdownEndBlock(countdownEndBlock);
}

function deleteCountdown() {
  IWorld(WorldContextConsumerLib._world()).experience__deleteCountdown();
}

function setStatus(string memory status) {
  IWorld(WorldContextConsumerLib._world()).experience__setStatus(status);
}

function deleteStatus() {
  IWorld(WorldContextConsumerLib._world()).experience__deleteStatus();
}

function setRegisterMsg(string memory registerMessage) {
  IWorld(WorldContextConsumerLib._world()).experience__setRegisterMsg(registerMessage);
}

function deleteRegisterMsg() {
  IWorld(WorldContextConsumerLib._world()).experience__deleteRegisterMsg();
}

function setUnregisterMsg(string memory unregisterMessage) {
  IWorld(WorldContextConsumerLib._world()).experience__setUnregisterMsg(unregisterMessage);
}

function deleteUnregisterMsg() {
  IWorld(WorldContextConsumerLib._world()).experience__deleteUnregisterMsg();
}

function setExperienceMetadata(ExperienceMetadataData memory metadata) {
  IWorld(WorldContextConsumerLib._world()).experience__setExperienceMetadata(metadata);
}

function deleteExperienceMetadata() {
  IWorld(WorldContextConsumerLib._world()).experience__deleteExperienceMetadata();
}

function setNotification(address player, string memory message) {
  IWorld(WorldContextConsumerLib._world()).experience__setNotification(player, message);
}

function deleteNotifications() {
  IWorld(WorldContextConsumerLib._world()).experience__deleteNotifications();
}

function setPlayers(address[] memory players) {
  IWorld(WorldContextConsumerLib._world()).experience__setPlayers(players);
}

function pushPlayers(address player) {
  IWorld(WorldContextConsumerLib._world()).experience__pushPlayers(player);
}

function popPlayers() {
  IWorld(WorldContextConsumerLib._world()).experience__popPlayers();
}

function updatePlayers(uint256 index, address player) {
  IWorld(WorldContextConsumerLib._world()).experience__updatePlayers(index, player);
}

function deletePlayers() {
  IWorld(WorldContextConsumerLib._world()).experience__deletePlayers();
}

function setNamespaceExperience(address experience) {
  IWorld(WorldContextConsumerLib._world()).experience__setNamespaceExperience(experience);
}

function deleteNamespaceExperience() {
  IWorld(WorldContextConsumerLib._world()).experience__deleteNamespaceExperience();
}
