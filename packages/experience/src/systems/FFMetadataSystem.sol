// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ForceFieldMetadata } from "../codegen/tables/ForceFieldMetadata.sol";
import { requireChipOwner, requireChipOwnerOrNoOwner } from "../Utils.sol";

contract FFMetadataSystem is System {
  function setForceFieldName(bytes32 entityId, string memory name) public {
    requireChipOwner(entityId);
    ForceFieldMetadata.setName(entityId, name);
  }

  function deleteForceFieldMetadata(bytes32 entityId) public {
    requireChipOwnerOrNoOwner(entityId);
    ForceFieldMetadata.deleteRecord(entityId);
  }
}
