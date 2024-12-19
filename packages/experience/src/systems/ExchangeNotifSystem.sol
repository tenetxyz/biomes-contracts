// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ExchangeNotif, ExchangeNotifData } from "../codegen/tables/ExchangeNotif.sol";
import { requireChipOwner, requireChipOwnerOrNoOwner } from "../Utils.sol";

contract ExchangeNotifSystem is System {
  function emitExchangeNotif(bytes32 entityId, ExchangeNotifData memory notifData) public {
    requireChipOwner(entityId);
    ExchangeNotif.set(entityId, notifData);
  }

  function deleteExchangeNotif(bytes32 entityId) public {
    requireChipOwnerOrNoOwner(entityId);
    ExchangeNotif.deleteRecord(entityId);
  }
}
