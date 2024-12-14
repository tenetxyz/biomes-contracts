// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";

import { Utils } from "@latticexyz/world/src/Utils.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";

import { ExchangeInfoData } from "../codegen/tables/ExchangeInfo.sol";
import { ExchangeNotifData } from "../codegen/tables/ExchangeNotif.sol";

function encodeAddressExchangeResourceId(address resourceAddress) pure returns (bytes32) {
  return bytes32(uint256(uint160(resourceAddress)));
}

function decodeAddressExchangeResourceId(bytes32 resourceId) pure returns (address) {
  return address(uint160(uint256(resourceId)));
}

function encodeObjectExchangeResourceId(uint8 objectTypeId) pure returns (bytes32) {
  return bytes32(uint256(objectTypeId));
}

function decodeObjectExchangeResourceId(bytes32 resourceId) pure returns (uint8) {
  return uint8(uint256(resourceId));
}

function setExchanges(bytes32 entityId, bytes32[] memory exchangeIds, ExchangeInfoData[] memory exchangeInfoData) {
  IWorld(WorldContextConsumerLib._world()).experience__setExchanges(entityId, exchangeIds, exchangeInfoData);
}

function addExchange(bytes32 entityId, bytes32 exchangeId, ExchangeInfoData memory exchangeInfoData) {
  IWorld(WorldContextConsumerLib._world()).experience__addExchange(entityId, exchangeId, exchangeInfoData);
}

function deleteExchange(bytes32 entityId, bytes32 exchangeId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteExchange(entityId, exchangeId);
}

function deleteExchanges(bytes32 entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteExchanges(entityId);
}

function setExchangeInUnitAmount(bytes32 entityId, bytes32 exchangeId, uint256 inUnitAmount) {
  IWorld(WorldContextConsumerLib._world()).experience__setExchangeInUnitAmount(entityId, exchangeId, inUnitAmount);
}

function setExchangeOutUnitAmount(bytes32 entityId, bytes32 exchangeId, uint256 outUnitAmount) {
  IWorld(WorldContextConsumerLib._world()).experience__setExchangeOutUnitAmount(entityId, exchangeId, outUnitAmount);
}

function setExchangeInMaxAmount(bytes32 entityId, bytes32 exchangeId, uint256 inMaxAmount) {
  IWorld(WorldContextConsumerLib._world()).experience__setExchangeInMaxAmount(entityId, exchangeId, inMaxAmount);
}

function setExchangeOutMaxAmount(bytes32 entityId, bytes32 exchangeId, uint256 outMaxAmount) {
  IWorld(WorldContextConsumerLib._world()).experience__setExchangeOutMaxAmount(entityId, exchangeId, outMaxAmount);
}

function emitExchangeNotif(bytes32 entityId, ExchangeNotifData memory notifData) {
  IWorld(WorldContextConsumerLib._world()).experience__emitExchangeNotif(entityId, notifData);
}

function deleteExchangeNotif(bytes32 entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteExchangeNotif(entityId);
}
