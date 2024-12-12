// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";

import { Utils } from "@latticexyz/world/src/Utils.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";

import { ChipMetadataData } from "../codegen/tables/ChipMetadata.sol";
import { ItemShopData } from "../codegen/tables/ItemShop.sol";
import { FFMetadataData } from "../codegen/tables/FFMetadata.sol";
import { ChestMetadataData } from "../codegen/tables/ChestMetadata.sol";
import { ForceFieldApprovalsData } from "../codegen/tables/ForceFieldApprovals.sol";
import { GateApprovalsData } from "../codegen/tables/GateApprovals.sol";
import { ItemShopNotifData } from "../codegen/tables/ItemShopNotif.sol";

function setChipMetadata(ChipMetadataData memory metadata) {
  IWorld(WorldContextConsumerLib._world()).experience__setChipMetadata(metadata);
}

function deleteChipMetadata() {
  IWorld(WorldContextConsumerLib._world()).experience__deleteChipMetadata();
}

function setChipNamespace(ResourceId namespaceId) {
  IWorld(WorldContextConsumerLib._world()).experience__setChipNamespace(namespaceId);
}

function deleteChipNamespace() {
  IWorld(WorldContextConsumerLib._world()).experience__deleteChipNamespace();
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

function emitShopNotif(bytes32 chestEntityId, ItemShopNotifData memory notifData) {
  IWorld(WorldContextConsumerLib._world()).experience__emitShopNotif(chestEntityId, notifData);
}

function deleteShopNotif(bytes32 chestEntityId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteShopNotif(chestEntityId);
}

function setGateApprovals(bytes32 entityId, GateApprovalsData memory approvals) {
  IWorld(WorldContextConsumerLib._world()).experience__setGateApprovals(entityId, approvals);
}

function deleteGateApprovals(bytes32 entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteGateApprovals(entityId);
}

function setGateApprovedPlayers(bytes32 entityId, address[] memory players) {
  IWorld(WorldContextConsumerLib._world()).experience__setGateApprovedPlayers(entityId, players);
}

function pushGateApprovedPlayer(bytes32 entityId, address player) {
  IWorld(WorldContextConsumerLib._world()).experience__pushGateApprovedPlayer(entityId, player);
}

function popGateApprovedPlayer(bytes32 entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__popGateApprovedPlayer(entityId);
}

function updateGateApprovedPlayer(bytes32 entityId, uint256 index, address player) {
  IWorld(WorldContextConsumerLib._world()).experience__updateGateApprovedPlayer(entityId, index, player);
}

function setGateApprovedNFT(bytes32 entityId, address[] memory nfts) {
  IWorld(WorldContextConsumerLib._world()).experience__setGateApprovedNFT(entityId, nfts);
}

function pushGateApprovedNFT(bytes32 entityId, address nft) {
  IWorld(WorldContextConsumerLib._world()).experience__pushGateApprovedNFT(entityId, nft);
}

function popGateApprovedNFT(bytes32 entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__popGateApprovedNFT(entityId);
}

function updateGateApprovedNFT(bytes32 entityId, uint256 index, address nft) {
  IWorld(WorldContextConsumerLib._world()).experience__updateGateApprovedNFT(entityId, index, nft);
}
