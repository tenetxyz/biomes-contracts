// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";

import { Utils } from "@latticexyz/world/src/Utils.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";
import { EntityId } from "@biomesaw/world/src/EntityId.sol";

import { ChipMetadataData } from "../codegen/tables/ChipMetadata.sol";
import { SmartItemMetadataData } from "../codegen/tables/SmartItemMetadata.sol";
import { GateApprovalsData } from "../codegen/tables/GateApprovals.sol";
import { ExchangeInfoData } from "../codegen/tables/ExchangeInfo.sol";
import { ExchangeNotifData } from "../codegen/tables/ExchangeNotif.sol";

function setChipMetadata(ChipMetadataData memory metadata) {
  IWorld(WorldContextConsumerLib._world()).experience__setChipMetadata(metadata);
}

function deleteChipMetadata() {
  IWorld(WorldContextConsumerLib._world()).experience__deleteChipMetadata();
}

function setChipAttacher(EntityId entityId, address attacher) {
  IWorld(WorldContextConsumerLib._world()).experience__setChipAttacher(entityId, attacher);
}

function deleteChipAttacher(EntityId entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteChipAttacher(entityId);
}

function setGateApprovals(EntityId entityId, GateApprovalsData memory approvals) {
  IWorld(WorldContextConsumerLib._world()).experience__setGateApprovals(entityId, approvals);
}

function deleteGateApprovals(EntityId entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteGateApprovals(entityId);
}

function setGateApprovedPlayers(EntityId entityId, address[] memory players) {
  IWorld(WorldContextConsumerLib._world()).experience__setGateApprovedPlayers(entityId, players);
}

function pushGateApprovedPlayer(EntityId entityId, address player) {
  IWorld(WorldContextConsumerLib._world()).experience__pushGateApprovedPlayer(entityId, player);
}

function popGateApprovedPlayer(EntityId entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__popGateApprovedPlayer(entityId);
}

function updateGateApprovedPlayer(EntityId entityId, uint256 index, address player) {
  IWorld(WorldContextConsumerLib._world()).experience__updateGateApprovedPlayer(entityId, index, player);
}

function setGateApprovedNFT(EntityId entityId, address[] memory nfts) {
  IWorld(WorldContextConsumerLib._world()).experience__setGateApprovedNFT(entityId, nfts);
}

function pushGateApprovedNFT(EntityId entityId, address nft) {
  IWorld(WorldContextConsumerLib._world()).experience__pushGateApprovedNFT(entityId, nft);
}

function popGateApprovedNFT(EntityId entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__popGateApprovedNFT(entityId);
}

function updateGateApprovedNFT(EntityId entityId, uint256 index, address nft) {
  IWorld(WorldContextConsumerLib._world()).experience__updateGateApprovedNFT(entityId, index, nft);
}

function setChipAdmin(EntityId entityId, address admin) {
  IWorld(WorldContextConsumerLib._world()).experience__setChipAdmin(entityId, admin);
}

function deleteChipAdmin(EntityId entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteChipAdmin(entityId);
}

function setSmartItemMetadata(EntityId entityId, SmartItemMetadataData memory metadata) {
  IWorld(WorldContextConsumerLib._world()).experience__setSmartItemMetadata(entityId, metadata);
}

function setSmartItemName(EntityId entityId, string memory name) {
  IWorld(WorldContextConsumerLib._world()).experience__setSmartItemName(entityId, name);
}

function setSmartItemDescription(EntityId entityId, string memory description) {
  IWorld(WorldContextConsumerLib._world()).experience__setSmartItemDescription(entityId, description);
}

function deleteSmartItemMetadata(EntityId entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteSmartItemMetadata(entityId);
}

function setExchanges(EntityId entityId, bytes32[] memory exchangeIds, ExchangeInfoData[] memory exchangeInfoData) {
  IWorld(WorldContextConsumerLib._world()).experience__setExchanges(entityId, exchangeIds, exchangeInfoData);
}

function addExchange(EntityId entityId, bytes32 exchangeId, ExchangeInfoData memory exchangeInfoData) {
  IWorld(WorldContextConsumerLib._world()).experience__addExchange(entityId, exchangeId, exchangeInfoData);
}

function deleteExchange(EntityId entityId, bytes32 exchangeId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteExchange(entityId, exchangeId);
}

function deleteExchanges(EntityId entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteExchanges(entityId);
}

function setExchangeInUnitAmount(EntityId entityId, bytes32 exchangeId, uint256 inUnitAmount) {
  IWorld(WorldContextConsumerLib._world()).experience__setExchangeInUnitAmount(entityId, exchangeId, inUnitAmount);
}

function setExchangeOutUnitAmount(EntityId entityId, bytes32 exchangeId, uint256 outUnitAmount) {
  IWorld(WorldContextConsumerLib._world()).experience__setExchangeOutUnitAmount(entityId, exchangeId, outUnitAmount);
}

function setExchangeInMaxAmount(EntityId entityId, bytes32 exchangeId, uint256 inMaxAmount) {
  IWorld(WorldContextConsumerLib._world()).experience__setExchangeInMaxAmount(entityId, exchangeId, inMaxAmount);
}

function setExchangeOutMaxAmount(EntityId entityId, bytes32 exchangeId, uint256 outMaxAmount) {
  IWorld(WorldContextConsumerLib._world()).experience__setExchangeOutMaxAmount(entityId, exchangeId, outMaxAmount);
}

function emitExchangeNotif(EntityId entityId, ExchangeNotifData memory notifData) {
  IWorld(WorldContextConsumerLib._world()).experience__emitExchangeNotif(entityId, notifData);
}

function deleteExchangeNotif(EntityId entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteExchangeNotif(entityId);
}

function setPipeAccess(EntityId targetEntityId, EntityId callerEntityId, bool depositAllowed, bool withdrawAllowed) {
  IWorld(WorldContextConsumerLib._world()).experience__setPipeAccess(
    targetEntityId,
    callerEntityId,
    depositAllowed,
    withdrawAllowed
  );
}

function deletePipeAccess(EntityId targetEntityId, EntityId callerEntityId) {
  IWorld(WorldContextConsumerLib._world()).experience__deletePipeAccess(targetEntityId, callerEntityId);
}

function deletePipeAccessList(EntityId targetEntityId) {
  IWorld(WorldContextConsumerLib._world()).experience__deletePipeAccessList(targetEntityId);
}
