// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";

import { Utils } from "@latticexyz/world/src/Utils.sol";
import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";

import { ChipMetadataData } from "../codegen/tables/ChipMetadata.sol";
import { ItemShopData } from "../codegen/tables/ItemShop.sol";
import { FFMetadataData } from "../codegen/tables/FFMetadata.sol";
import { ChestMetadataData } from "../codegen/tables/ChestMetadata.sol";
import { ForceFieldApprovalsData } from "../codegen/tables/ForceFieldApprovals.sol";

function setChipMetadata(ChipMetadataData memory metadata) {
  IWorld(WorldContextConsumerLib._world()).experience__setChipMetadata(metadata);
}

function deleteChipMetadata() {
  IWorld(WorldContextConsumerLib._world()).experience__deleteChipMetadata();
}

function setChipAttacher(bytes32 entityId, address attacher) {
  IWorld(WorldContextConsumerLib._world()).experience__setChipAttacher(entityId, attacher);
}

function deleteChipAttacher(bytes32 entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteChipAttacher(entityId);
}

function setShop(bytes32 entityId, ItemShopData memory shopData) {
  IWorld(WorldContextConsumerLib._world()).experience__setShop(entityId, shopData);
}

function deleteShop(bytes32 entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteShop(entityId);
}

function setBuyShop(bytes32 entityId, uint8 buyObjectTypeId, uint256 buyPrice, address paymentToken) {
  IWorld(WorldContextConsumerLib._world()).experience__setBuyShop(entityId, buyObjectTypeId, buyPrice, paymentToken);
}

function setSellShop(bytes32 entityId, uint8 sellObjectTypeId, uint256 sellPrice, address paymentToken) {
  IWorld(WorldContextConsumerLib._world()).experience__setSellShop(entityId, sellObjectTypeId, sellPrice, paymentToken);
}

function setShopBalance(bytes32 entityId, uint256 balance) {
  IWorld(WorldContextConsumerLib._world()).experience__setShopBalance(entityId, balance);
}

function setBuyPrice(bytes32 entityId, uint256 buyPrice) {
  IWorld(WorldContextConsumerLib._world()).experience__setBuyPrice(entityId, buyPrice);
}

function setSellPrice(bytes32 entityId, uint256 sellPrice) {
  IWorld(WorldContextConsumerLib._world()).experience__setSellPrice(entityId, sellPrice);
}

function setShopObjectTypeId(bytes32 entityId, uint8 objectTypeId) {
  IWorld(WorldContextConsumerLib._world()).experience__setShopObjectTypeId(entityId, objectTypeId);
}

function setChestMetadata(bytes32 entityId, ChestMetadataData memory metadata) {
  IWorld(WorldContextConsumerLib._world()).experience__setChestMetadata(entityId, metadata);
}

function setChestName(bytes32 entityId, string memory name) {
  IWorld(WorldContextConsumerLib._world()).experience__setChestName(entityId, name);
}

function setChestDescription(bytes32 entityId, string memory description) {
  IWorld(WorldContextConsumerLib._world()).experience__setChestDescription(entityId, description);
}

function deleteChestMetadata(bytes32 entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteChestMetadata(entityId);
}

function setForceFieldMetadata(bytes32 entityId, FFMetadataData memory metadata) {
  IWorld(WorldContextConsumerLib._world()).experience__setForceFieldMetadata(entityId, metadata);
}

function setForceFieldName(bytes32 entityId, string memory name) {
  IWorld(WorldContextConsumerLib._world()).experience__setForceFieldName(entityId, name);
}

function setForceFieldDescription(bytes32 entityId, string memory description) {
  IWorld(WorldContextConsumerLib._world()).experience__setForceFieldDescription(entityId, description);
}

function deleteForceFieldMetadata(bytes32 entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteForceFieldMetadata(entityId);
}

function setForceFieldApprovals(bytes32 entityId, ForceFieldApprovalsData memory approvals) {
  IWorld(WorldContextConsumerLib._world()).experience__setForceFieldApprovals(entityId, approvals);
}

function deleteForceFieldApprovals(bytes32 entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteForceFieldApprovals(entityId);
}

function setFFApprovedPlayers(bytes32 entityId, address[] memory players) {
  IWorld(WorldContextConsumerLib._world()).experience__setFFApprovedPlayers(entityId, players);
}

function pushFFApprovedPlayer(bytes32 entityId, address player) {
  IWorld(WorldContextConsumerLib._world()).experience__pushFFApprovedPlayer(entityId, player);
}

function popFFApprovedPlayer(bytes32 entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__popFFApprovedPlayer(entityId);
}

function updateFFApprovedPlayer(bytes32 entityId, uint256 index, address player) {
  IWorld(WorldContextConsumerLib._world()).experience__updateFFApprovedPlayer(entityId, index, player);
}

function setFFApprovedNFT(bytes32 entityId, address[] memory nfts) {
  IWorld(WorldContextConsumerLib._world()).experience__setFFApprovedNFT(entityId, nfts);
}

function pushFFApprovedNFT(bytes32 entityId, address nft) {
  IWorld(WorldContextConsumerLib._world()).experience__pushFFApprovedNFT(entityId, nft);
}

function popFFApprovedNFT(bytes32 entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__popFFApprovedNFT(entityId);
}

function updateFFApprovedNFT(bytes32 entityId, uint256 index, address nft) {
  IWorld(WorldContextConsumerLib._world()).experience__updateFFApprovedNFT(entityId, index, nft);
}
