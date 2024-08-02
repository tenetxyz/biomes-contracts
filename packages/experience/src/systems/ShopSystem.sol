// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { Chip, ChipData } from "@biomesaw/world/src/codegen/tables/Chip.sol";
import { Shop, ShopData } from "../codegen/tables/Shop.sol";
import { requireChipOwner, requireChipOwnerOrNoOwner } from "../Utils.sol";

contract ShopSystem is System {
  function setShop(bytes32 entityId, ShopData memory shopData) public {
    requireChipOwner(entityId);
    Shop.set(entityId, shopData);
  }

  function deleteShop(bytes32 entityId) public {
    requireChipOwnerOrNoOwner(entityId);
    Shop.deleteRecord(entityId);
  }

  function setBuyShop(bytes32 entityId, uint8 buyObjectTypeId, uint256 buyPrice, address paymentToken) public {
    requireChipOwner(entityId);
    Shop.setObjectTypeId(entityId, buyObjectTypeId);
    Shop.setBuyPrice(entityId, buyPrice);
    Shop.setPaymentToken(entityId, paymentToken);
  }

  function setSellShop(bytes32 entityId, uint8 sellObjectTypeId, uint256 sellPrice, address paymentToken) public {
    requireChipOwner(entityId);
    Shop.setObjectTypeId(entityId, sellObjectTypeId);
    Shop.setSellPrice(entityId, sellPrice);
    Shop.setPaymentToken(entityId, paymentToken);
  }

  function setShopBalance(bytes32 entityId, uint256 balance) public {
    requireChipOwner(entityId);
    Shop.setBalance(entityId, balance);
  }
}
