// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { EntityId } from "@biomesaw/world/src/EntityId.sol";

import { ProgramAdmin } from "../codegen/tables/ProgramAdmin.sol";
import { requireProgramOwner, requireProgramOwnerOrNoOwner } from "../Utils.sol";

contract ProgramAdminSystem is System {
  function setProgramAdmin(EntityId entityId, address admin) public {
    requireProgramOwner(entityId);
    ProgramAdmin.setAdmin(entityId, admin);
  }

  function deleteProgramAdmin(EntityId entityId) public {
    requireProgramOwnerOrNoOwner(entityId);
    ProgramAdmin.deleteRecord(entityId);
  }
}
