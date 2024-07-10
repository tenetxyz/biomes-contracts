// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";

import { Utils } from "@latticexyz/world/src/Utils.sol";
import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";

import { ShopData } from "../codegen/tables/Shop.sol";
import { ChipMetadataData } from "../codegen/tables/ChipMetadata.sol";

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

function setShop(bytes32 entityId, ShopData memory shopData) {
  IWorld(WorldContextConsumerLib._world()).experience__setShop(entityId, shopData);
}

function deleteShop(bytes32 entityId) {
  IWorld(WorldContextConsumerLib._world()).experience__deleteShop(entityId);
}

function setBuyShop(bytes32 entityId, uint8 buyObjectTypeId, uint256 buyPrice) {
  IWorld(WorldContextConsumerLib._world()).experience__setBuyShop(entityId, buyObjectTypeId, buyPrice);
}

function setSellShop(bytes32 entityId, uint8 sellObjectTypeId, uint256 sellPrice) {
  IWorld(WorldContextConsumerLib._world()).experience__setSellShop(entityId, sellObjectTypeId, sellPrice);
}

function setShopBalance(bytes32 entityId, uint256 balance) {
  IWorld(WorldContextConsumerLib._world()).experience__setShopBalance(entityId, balance);
}
