// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";

import { Utils } from "@latticexyz/world/src/Utils.sol";
import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { CountdownData } from "../codegen/tables/Countdown.sol";
import { ExperienceMetadataData } from "../codegen/tables/ExperienceMetadata.sol";
import { ERC20MetadataData } from "../codegen/tables/ERC20Metadata.sol";
import { ERC721MetadataData } from "../codegen/tables/ERC721Metadata.sol";
import { ResourceType } from "../codegen/common.sol";

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

function setJoinFee(uint256 joinFee) {
  IWorld(WorldContextConsumerLib._world()).experience__setJoinFee(joinFee);
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

function setTokens(address[] memory tokens) {
  IWorld(WorldContextConsumerLib._world()).experience__setTokens(tokens);
}

function pushTokens(address token) {
  IWorld(WorldContextConsumerLib._world()).experience__pushTokens(token);
}

function popTokens() {
  IWorld(WorldContextConsumerLib._world()).experience__popTokens();
}

function updateTokens(uint256 index, address token) {
  IWorld(WorldContextConsumerLib._world()).experience__updateTokens(index, token);
}

function deleteTokens() {
  IWorld(WorldContextConsumerLib._world()).experience__deleteTokens();
}

function setNfts(address[] memory nfts) {
  IWorld(WorldContextConsumerLib._world()).experience__setNfts(nfts);
}

function pushNfts(address nft) {
  IWorld(WorldContextConsumerLib._world()).experience__pushNfts(nft);
}

function popNfts() {
  IWorld(WorldContextConsumerLib._world()).experience__popNfts();
}

function updateNfts(uint256 index, address nft) {
  IWorld(WorldContextConsumerLib._world()).experience__updateNfts(index, nft);
}

function deleteNfts() {
  IWorld(WorldContextConsumerLib._world()).experience__deleteNfts();
}

function setTokenMetadata(ERC20MetadataData memory metadata) {
  IWorld(WorldContextConsumerLib._world()).experience__setTokenMetadata(metadata);
}

function deleteTokenMetadata() {
  IWorld(WorldContextConsumerLib._world()).experience__deleteTokenMetadata();
}

function setNFTMetadata(ERC721MetadataData memory metadata) {
  IWorld(WorldContextConsumerLib._world()).experience__setNFTMetadata(metadata);
}

function setMUDNFTMetadata(ResourceId namespaceId, ERC721MetadataData memory metadata) {
  IWorld(WorldContextConsumerLib._world()).experience__setMUDNFTMetadata(namespaceId, metadata);
}

function deleteNFTMetadata() {
  IWorld(WorldContextConsumerLib._world()).experience__deleteNFTMetadata();
}

function setNamespaceId(ResourceId namespaceId) {
  IWorld(WorldContextConsumerLib._world()).experience__setNamespaceId(namespaceId);
}

function deleteNamespaceId() {
  IWorld(WorldContextConsumerLib._world()).experience__deleteNamespaceId();
}

function setAsset(address asset, ResourceType assetType) {
  IWorld(WorldContextConsumerLib._world()).experience__setAsset(asset, assetType);
}

function deleteAsset(address asset) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteAsset(asset);
}
