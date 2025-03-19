// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { EntityId } from "@biomesaw/world/src/EntityId.sol";
import { Program } from "@biomesaw/world/src/codegen/tables/Program.sol";
import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";

function requireProgramOwner(EntityId entityId) view {
  require(
    entityId.getProgramAddress() == WorldContextConsumerLib._msgSender(),
    "Only the program address can perform this action."
  );
}

function requireProgramOwnerOrNoOwner(EntityId entityId) view {
  address programAddress = entityId.getProgramAddress();
  require(
    programAddress == WorldContextConsumerLib._msgSender() || programAddress == address(0),
    "Only the program address can perform this action."
  );
}
