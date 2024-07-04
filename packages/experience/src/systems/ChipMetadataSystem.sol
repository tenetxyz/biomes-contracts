// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ChipMetadata, ChipMetadataData } from "../codegen/tables/ChipMetadata.sol";

import { getExperienceAddress } from "../Utils.sol";

contract ChipMetadataSystem is System {
  function setChipMetadata(ChipMetadataData memory metadata) public {
    ChipMetadata.set(getExperienceAddress(_msgSender()), metadata);
  }

  function deleteChipMetadata() public {
    ChipMetadata.deleteRecord(getExperienceAddress(_msgSender()));
  }
}
