// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Chip } from "@biomesaw/world/src/codegen/tables/Chip.sol";
import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";

function requireChipOwner(bytes32 entityId) view {
  require(
    Chip.getChipAddress(entityId) == WorldContextConsumerLib._msgSender(),
    "Only the chip address can perform this action."
  );
}

function requireChipOwnerOrNoOwner(bytes32 entityId) view {
  address chipAddress = Chip.getChipAddress(entityId);
  require(
    chipAddress == WorldContextConsumerLib._msgSender() || chipAddress == address(0),
    "Only the chip address can perform this action."
  );
}
