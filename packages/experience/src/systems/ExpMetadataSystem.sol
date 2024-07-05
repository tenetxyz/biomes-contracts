// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ExperienceMetadata, ExperienceMetadataData } from "../codegen/tables/ExperienceMetadata.sol";

import { getExperienceAddress } from "../Utils.sol";

contract ExpMetadataSystem is System {
  function setExperienceMetadata(ExperienceMetadataData memory metadata) public {
    ExperienceMetadata.set(getExperienceAddress(_msgSender()), metadata);
  }

  function setJoinFee(uint256 joinFee) public {
    ExperienceMetadata.setJoinFee(getExperienceAddress(_msgSender()), joinFee);
  }

  function deleteExperienceMetadata() public {
    ExperienceMetadata.deleteRecord(getExperienceAddress(_msgSender()));
  }
}
