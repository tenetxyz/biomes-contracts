// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ExchangeInChest, ExchangeInChestData } from "../codegen/tables/ExchangeInChest.sol";
import { ExchangeOutChest, ExchangeOutChestData } from "../codegen/tables/ExchangeOutChest.sol";
import { requireChipOwner, requireChipOwnerOrNoOwner } from "../Utils.sol";

contract ExchangeSystem is System {
  function setExchangeInChest(bytes32 entityId, ExchangeInChestData memory exchangeInChestData) public {
    requireChipOwner(entityId);
    ExchangeInChest.set(entityId, exchangeInChestData);
  }

  function deleteExchangeInChest(bytes32 entityId) public {
    requireChipOwnerOrNoOwner(entityId);
    ExchangeInChest.deleteRecord(entityId);
  }

  function setExchangeOutChest(bytes32 entityId, ExchangeOutChestData memory exchangeOutChestData) public {
    requireChipOwner(entityId);
    ExchangeOutChest.set(entityId, exchangeOutChestData);
  }

  function deleteExchangeOutChest(bytes32 entityId) public {
    requireChipOwnerOrNoOwner(entityId);
    ExchangeOutChest.deleteRecord(entityId);
  }

  function setExchangeInChestInUnitAmount(bytes32 entityId, uint256 inUnitAmount) public {
    requireChipOwner(entityId);
    ExchangeInChest.setInUnitAmount(entityId, inUnitAmount);
  }

  function setExchangeInChestOutUnitAmount(bytes32 entityId, uint256 outUnitAmount) public {
    requireChipOwner(entityId);
    ExchangeInChest.setOutUnitAmount(entityId, outUnitAmount);
  }

  function setExchangeInChestOutBalance(bytes32 entityId, uint256 balance) public {
    requireChipOwner(entityId);
    ExchangeInChest.setOutBalance(entityId, balance);
  }

  function setExchangeOutChestInUnitAmount(bytes32 entityId, uint256 inUnitAmount) public {
    requireChipOwner(entityId);
    ExchangeOutChest.setInUnitAmount(entityId, inUnitAmount);
  }

  function setExchangeOutChestOutUnitAmount(bytes32 entityId, uint256 outUnitAmount) public {
    requireChipOwner(entityId);
    ExchangeOutChest.setOutUnitAmount(entityId, outUnitAmount);
  }

  function setExchangeOutChestOutBalance(bytes32 entityId, uint256 balance) public {
    requireChipOwner(entityId);
    ExchangeOutChest.setOutBalance(entityId, balance);
  }
}
