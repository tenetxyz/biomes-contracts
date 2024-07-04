// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { Chip, ChipData } from "@biomesaw/world/src/codegen/tables/Chip.sol";
import { ChipAttachment } from "../codegen/tables/ChipAttachment.sol";

import { getExperienceAddress } from "../Utils.sol";

contract ChipAttachmentSystem is System {
  function setChipAttacher(bytes32 entityId, address attacher) public {
    require(
      Chip.getChipAddress(entityId) == getExperienceAddress(_msgSender()),
      "ChipAttachmentSystem: Only the chip address can set the attacher."
    );
    ChipAttachment.setAttacher(entityId, attacher);
  }

  function deleteChipAttacher(bytes32 entityId) public {
    require(
      Chip.getChipAddress(entityId) == getExperienceAddress(_msgSender()),
      "ChipAttachmentSystem: Only the chip address can delete the attacher."
    );
    ChipAttachment.deleteRecord(entityId);
  }
}
