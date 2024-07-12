// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Equipped } from "../codegen/tables/Equipped.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";

import { requireValidPlayer } from "../utils/PlayerUtils.sol";

contract UnequipSystem is System {
  function unequip() public {
    (bytes32 playerEntityId, ) = requireValidPlayer(_msgSender());
    if (Equipped._get(playerEntityId) == bytes32(0)) {
      return;
    }
    Equipped._deleteRecord(playerEntityId);
    PlayerActivity._set(playerEntityId, block.timestamp);
  }
}
