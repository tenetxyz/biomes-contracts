// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { Chip, ChipData } from "@biomesaw/world/src/codegen/tables/Chip.sol";
import { ChipAdmin } from "../codegen/tables/ChipAdmin.sol";
import { requireChipOwner, requireChipOwnerOrNoOwner } from "../Utils.sol";

contract ChipAdminSystem is System {
  function setChipAdmin(bytes32 entityId, address admin) public {
    requireChipOwner(entityId);
    ChipAdmin.setAdmin(entityId, admin);
  }

  function deleteChipAdmin(bytes32 entityId) public {
    requireChipOwnerOrNoOwner(entityId);
    ChipAdmin.deleteRecord(entityId);
  }
}
