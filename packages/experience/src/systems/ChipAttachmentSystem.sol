// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { Chip, ChipData } from "@biomesaw/world/src/codegen/tables/Chip.sol";
import { ChipAttachment } from "../codegen/tables/ChipAttachment.sol";
import { requireChipOwner, requireChipOwnerOrNoOwner } from "../Utils.sol";

contract ChipAttachmentSystem is System {
  function setChipAttacher(bytes32 entityId, address attacher) public {
    requireChipOwner(entityId);
    ChipAttachment.setAttacher(entityId, attacher);
  }

  function deleteChipAttacher(bytes32 entityId) public {
    requireChipOwnerOrNoOwner(entityId);
    ChipAttachment.deleteRecord(entityId);
  }
}
