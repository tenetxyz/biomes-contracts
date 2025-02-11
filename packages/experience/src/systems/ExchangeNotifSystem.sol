// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { EntityId } from "@biomesaw/world/src/EntityId.sol";

import { ExchangeNotif, ExchangeNotifData } from "../codegen/tables/ExchangeNotif.sol";
import { requireChipOwner, requireChipOwnerOrNoOwner } from "../Utils.sol";

contract ExchangeNotifSystem is System {
  function emitExchangeNotif(EntityId entityId, ExchangeNotifData memory notifData) public {
    requireChipOwner(entityId);
    ExchangeNotif.set(entityId, notifData);
  }

  function deleteExchangeNotif(EntityId entityId) public {
    requireChipOwnerOrNoOwner(entityId);
    ExchangeNotif.deleteRecord(entityId);
  }
}
