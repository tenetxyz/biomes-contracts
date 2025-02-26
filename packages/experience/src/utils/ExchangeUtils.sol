// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";

import { Utils } from "@latticexyz/world/src/Utils.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";

import { EntityId } from "@biomesaw/world/src/EntityId.sol";

import { Exchanges } from "../codegen/tables/Exchanges.sol";

function encodeAddressExchangeResourceId(address resourceAddress) pure returns (bytes32) {
  return bytes32(uint256(uint160(resourceAddress)));
}

function decodeAddressExchangeResourceId(bytes32 resourceId) pure returns (address) {
  return address(uint160(uint256(resourceId)));
}

function encodeObjectExchangeResourceId(uint16 objectTypeId) pure returns (bytes32) {
  return bytes32(uint256(objectTypeId));
}

function decodeObjectExchangeResourceId(bytes32 resourceId) pure returns (uint16) {
  return uint16(uint256(resourceId));
}

function exchangeExists(EntityId entityId, bytes32 exchangeId) view returns (bool) {
  bytes32[] memory exchangeIds = Exchanges.get(entityId);
  for (uint256 i = 0; i < exchangeIds.length; i++) {
    if (exchangeIds[i] == exchangeId) {
      return true;
    }
  }
  return false;
}
