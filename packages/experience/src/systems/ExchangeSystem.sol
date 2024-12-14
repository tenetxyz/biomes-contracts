// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ExchangeInfo, ExchangeInfoData } from "../codegen/tables/ExchangeInfo.sol";
import { Exchanges } from "../codegen/tables/Exchanges.sol";
import { requireChipOwner, requireChipOwnerOrNoOwner } from "../Utils.sol";

contract ExchangeSystem is System {
  function exchangeExists(bytes32 entityId, bytes32 exchangeId) internal view returns (bool) {
    bytes32[] memory exchangeIds = Exchanges.get(entityId);
    for (uint256 i = 0; i < exchangeIds.length; i++) {
      if (exchangeIds[i] == exchangeId) {
        return true;
      }
    }
    return false;
  }

  function setExchanges(
    bytes32 entityId,
    bytes32[] memory exchangeIds,
    ExchangeInfoData[] memory exchangeInfoData
  ) public {
    requireChipOwner(entityId);
    require(exchangeIds.length == exchangeInfoData.length, "Exchange ids and exchange info data length mismatch");
    for (uint256 i = 0; i < exchangeIds.length; i++) {
      ExchangeInfo.set(entityId, exchangeIds[i], exchangeInfoData[i]);
    }
    Exchanges.set(entityId, exchangeIds);
  }

  function addExchange(bytes32 entityId, bytes32 exchangeId, ExchangeInfoData memory exchangeInfoData) public {
    requireChipOwner(entityId);
    require(!exchangeExists(entityId, exchangeId), "Exchange already exists");
    ExchangeInfo.set(entityId, exchangeId, exchangeInfoData);
    Exchanges.push(entityId, exchangeId);
  }

  function deleteExchange(bytes32 entityId, bytes32 exchangeId) public {
    requireChipOwner(entityId);
    require(exchangeExists(entityId, exchangeId), "Exchange does not exist");
    bytes32[] memory exchangeIds = Exchanges.get(entityId);
    bytes32[] memory newExchangeIds = new bytes32[](exchangeIds.length - 1);
    uint256 newIndex = 0;
    for (uint256 i = 0; i < exchangeIds.length; i++) {
      if (exchangeIds[i] != exchangeId) {
        newExchangeIds[newIndex] = exchangeIds[i];
        newIndex++;
      }
    }

    ExchangeInfo.deleteRecord(entityId, exchangeId);
    Exchanges.set(entityId, newExchangeIds);
  }

  function deleteExchanges(bytes32 entityId) public {
    requireChipOwnerOrNoOwner(entityId);
    bytes32[] memory exchangeIds = Exchanges.get(entityId);
    for (uint256 i = 0; i < exchangeIds.length; i++) {
      ExchangeInfo.deleteRecord(entityId, exchangeIds[i]);
    }
    Exchanges.deleteRecord(entityId);
  }

  function setExchangeInUnitAmount(bytes32 entityId, bytes32 exchangeId, uint256 inUnitAmount) public {
    requireChipOwner(entityId);
    require(exchangeExists(entityId, exchangeId), "Exchange does not exist");
    ExchangeInfo.setInUnitAmount(entityId, exchangeId, inUnitAmount);
  }

  function setExchangeOutUnitAmount(bytes32 entityId, bytes32 exchangeId, uint256 outUnitAmount) public {
    requireChipOwner(entityId);
    require(exchangeExists(entityId, exchangeId), "Exchange does not exist");
    ExchangeInfo.setOutUnitAmount(entityId, exchangeId, outUnitAmount);
  }

  function setExchangeInMaxAmount(bytes32 entityId, bytes32 exchangeId, uint256 inMaxAmount) public {
    requireChipOwner(entityId);
    require(exchangeExists(entityId, exchangeId), "Exchange does not exist");
    ExchangeInfo.setInMaxAmount(entityId, exchangeId, inMaxAmount);
  }

  function setExchangeOutMaxAmount(bytes32 entityId, bytes32 exchangeId, uint256 outMaxAmount) public {
    requireChipOwner(entityId);
    require(exchangeExists(entityId, exchangeId), "Exchange does not exist");
    ExchangeInfo.setOutMaxAmount(entityId, exchangeId, outMaxAmount);
  }
}
