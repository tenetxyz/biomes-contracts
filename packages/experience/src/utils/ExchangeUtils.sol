// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";

import { Utils } from "@latticexyz/world/src/Utils.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";

import { ExchangeInChestData } from "../codegen/tables/ExchangeInChest.sol";
import { ExchangeOutChestData } from "../codegen/tables/ExchangeOutChest.sol";

function setExchangeInChest(bytes32 entityId, ExchangeInChestData memory exchangeInChestData) {
  IWorld(WorldContextConsumerLib._world()).experience__setExchangeInChest(entityId, exchangeInChestData);
}

function deleteExchangeInChest(bytes32 entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteExchangeInChest(entityId);
}

function setExchangeOutChest(bytes32 entityId, ExchangeOutChestData memory exchangeOutChestData) {
  IWorld(WorldContextConsumerLib._world()).experience__setExchangeOutChest(entityId, exchangeOutChestData);
}

function deleteExchangeOutChest(bytes32 entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteExchangeOutChest(entityId);
}

function setExchangeInChestInUnitAmount(bytes32 entityId, uint256 inUnitAmount) {
  IWorld(WorldContextConsumerLib._world()).experience__setExchangeInChestInUnitAmount(entityId, inUnitAmount);
}

function setExchangeInChestOutUnitAmount(bytes32 entityId, uint256 outUnitAmount) {
  IWorld(WorldContextConsumerLib._world()).experience__setExchangeInChestOutUnitAmount(entityId, outUnitAmount);
}

function setExchangeInChestOutBalance(bytes32 entityId, uint256 balance) {
  IWorld(WorldContextConsumerLib._world()).experience__setExchangeInChestOutBalance(entityId, balance);
}

function setExchangeOutChestInUnitAmount(bytes32 entityId, uint256 inUnitAmount) {
  IWorld(WorldContextConsumerLib._world()).experience__setExchangeOutChestInUnitAmount(entityId, inUnitAmount);
}

function setExchangeOutChestOutUnitAmount(bytes32 entityId, uint256 outUnitAmount) {
  IWorld(WorldContextConsumerLib._world()).experience__setExchangeOutChestOutUnitAmount(entityId, outUnitAmount);
}

function setExchangeOutChestOutBalance(bytes32 entityId, uint256 balance) {
  IWorld(WorldContextConsumerLib._world()).experience__setExchangeOutChestOutBalance(entityId, balance);
}
