// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ExchangeChest, ExchangeChestData } from "../codegen/tables/ExchangeChest.sol";
import { ExchangeType } from "../codegen/common.sol";
import { requireChipOwner, requireChipOwnerOrNoOwner } from "../Utils.sol";

contract ExchangeSystem is System {
  function setExchangeChest(bytes32 entityId, ExchangeChestData memory exchangeChestData) public {
    requireChipOwner(entityId);
    ExchangeChest.set(entityId, exchangeChestData);
  }

  function deleteExchangeChest(bytes32 entityId) public {
    requireChipOwnerOrNoOwner(entityId);
    ExchangeChest.deleteRecord(entityId);
  }

  function setExchangeChestOutBalance(bytes32 entityId, uint256 balance) public {
    requireChipOwner(entityId);
    ExchangeChest.setOutBalance(entityId, balance);
  }

  function setExchangeChestInAmount(bytes32 entityId, uint256 inAmount) public {
    requireChipOwner(entityId);
    ExchangeChest.setInAmount(entityId, inAmount);
  }

  function setExchangeChestOutAmount(bytes32 entityId, uint256 outAmount) public {
    requireChipOwner(entityId);
    ExchangeChest.setOutAmount(entityId, outAmount);
  }
}
