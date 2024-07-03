// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ExperienceMetadata, ExperienceMetadataData } from "../codegen/tables/ExperienceMetadata.sol";

contract ExperienceSystem is System {
  function setExperienceMetadata(uint256 id, ExperienceMetadataData memory data) public {
    ExperienceMetadata.set(_msgSender(), data);
  }
}
