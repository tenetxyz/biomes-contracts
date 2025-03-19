// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ProgramMetadata, ProgramMetadataData } from "../codegen/tables/ProgramMetadata.sol";

contract ProgramMetadataSystem is System {
  function setProgramMetadata(ProgramMetadataData memory metadata) public {
    ProgramMetadata.set(_msgSender(), metadata);
  }

  function deleteProgramMetadata() public {
    ProgramMetadata.deleteRecord(_msgSender());
  }
}
