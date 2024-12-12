// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";

import { Utils } from "@latticexyz/world/src/Utils.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";

import { ExchangeChestData } from "../codegen/tables/ExchangeChest.sol";

function setExchangeChest(bytes32 entityId, ExchangeChestData memory exchangeChestData) {
  IWorld(WorldContextConsumerLib._world()).experience__setExchangeChest(entityId, exchangeChestData);
}

function deleteExchangeChest(bytes32 entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteExchangeChest(entityId);
}

function setExchangeChestOutBalance(bytes32 entityId, uint256 balance) {
  IWorld(WorldContextConsumerLib._world()).experience__setExchangeChestOutBalance(entityId, balance);
}

function setExchangeChestInAmount(bytes32 entityId, uint256 inAmount) {
  IWorld(WorldContextConsumerLib._world()).experience__setExchangeChestInAmount(entityId, inAmount);
}

function setExchangeChestOutAmount(bytes32 entityId, uint256 outAmount) {
  IWorld(WorldContextConsumerLib._world()).experience__setExchangeChestOutAmount(entityId, outAmount);
}
