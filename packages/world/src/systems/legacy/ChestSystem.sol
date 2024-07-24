// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

contract ChestSystem is System {
  function strengthenChest(
    bytes32 chestEntityId,
    uint8 strengthenObjectTypeId,
    uint16 strengthenObjectTypeAmount
  ) public {
    revert("ChestSystem: deprecated");
  }

  function setChestOnTransferHook(bytes32 chestEntityId, address hookAddress) public {
    revert("ChestSystem: deprecated");
  }
}
