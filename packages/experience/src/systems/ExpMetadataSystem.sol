// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ExperienceMetadata, ExperienceMetadataData } from "../codegen/tables/ExperienceMetadata.sol";

contract ExpMetadataSystem is System {
  function setExperienceMetadata(ExperienceMetadataData memory metadata) public {
    ExperienceMetadata.set(_msgSender(), metadata);
  }

  function deleteExperienceMetadata() public {
    ExperienceMetadata.deleteRecord(_msgSender());
  }
}
