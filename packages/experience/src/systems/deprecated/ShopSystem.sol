// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { Chip, ChipData } from "@biomesaw/world/src/codegen/tables/Chip.sol";
import { ItemShop, ItemShopData } from "../../codegen/tables/ItemShop.sol";
import { ShopType } from "../../codegen/common.sol";
import { requireChipOwner, requireChipOwnerOrNoOwner } from "../../Utils.sol";

contract ShopSystem is System {
  function setShop(bytes32 entityId, ItemShopData memory shopData) public {
    requireChipOwner(entityId);
    ItemShop.set(entityId, shopData);
  }

  function deleteShop(bytes32 entityId) public {
    requireChipOwnerOrNoOwner(entityId);
    ItemShop.deleteRecord(entityId);
  }

  function setBuyShop(bytes32 entityId, uint8 buyObjectTypeId, uint256 buyPrice, address paymentToken) public {
    requireChipOwner(entityId);
    ItemShop.set(
      entityId,
      ItemShopData({
        shopType: ShopType.Buy,
        objectTypeId: buyObjectTypeId,
        buyPrice: buyPrice,
        paymentToken: paymentToken,
        sellPrice: 0,
        balance: 0
      })
    );
  }

  function setSellShop(bytes32 entityId, uint8 sellObjectTypeId, uint256 sellPrice, address paymentToken) public {
    requireChipOwner(entityId);
    ItemShop.set(
      entityId,
      ItemShopData({
        shopType: ShopType.Sell,
        objectTypeId: sellObjectTypeId,
        sellPrice: sellPrice,
        paymentToken: paymentToken,
        buyPrice: 0,
        balance: 0
      })
    );
  }

  function setShopBalance(bytes32 entityId, uint256 balance) public {
    requireChipOwner(entityId);
    ItemShop.setBalance(entityId, balance);
  }

  function setBuyPrice(bytes32 entityId, uint256 buyPrice) public {
    requireChipOwner(entityId);
    ItemShop.setBuyPrice(entityId, buyPrice);
  }

  function setSellPrice(bytes32 entityId, uint256 sellPrice) public {
    requireChipOwner(entityId);
    ItemShop.setSellPrice(entityId, sellPrice);
  }

  function setShopObjectTypeId(bytes32 entityId, uint16 objectTypeId) public {
    requireChipOwner(entityId);
    ItemShop.setObjectTypeId(entityId, objectTypeId);
  }
}
