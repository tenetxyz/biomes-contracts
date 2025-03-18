// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { EntityId } from "@biomesaw/world/src/EntityId.sol";

import { ProgramAttachment } from "../codegen/tables/ProgramAttachment.sol";
import { requireProgramOwner, requireProgramOwnerOrNoOwner } from "../Utils.sol";

contract ProgramAttachmentSystem is System {
  function setProgramAttacher(EntityId entityId, address attacher) public {
    requireProgramOwner(entityId);
    ProgramAttachment.setAttacher(entityId, attacher);
  }

  function deleteProgramAttacher(EntityId entityId) public {
    requireProgramOwnerOrNoOwner(entityId);
    ProgramAttachment.deleteRecord(entityId);
  }
}
