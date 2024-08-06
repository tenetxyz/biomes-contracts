// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { FFMetadata, FFMetadataData } from "../codegen/tables/FFMetadata.sol";
import { requireChipOwner, requireChipOwnerOrNoOwner } from "../Utils.sol";

contract FFMetadataSystem is System {
  function setForceFieldMetadata(bytes32 entityId, FFMetadataData memory metadata) public {
    requireChipOwner(entityId);
    FFMetadata.set(entityId, metadata);
  }

  function setForceFieldName(bytes32 entityId, string memory name) public {
    requireChipOwner(entityId);
    FFMetadata.setName(entityId, name);
  }

  function setForceFieldDescription(bytes32 entityId, string memory description) public {
    requireChipOwner(entityId);
    FFMetadata.setDescription(entityId, description);
  }

  function deleteForceFieldMetadata(bytes32 entityId) public {
    requireChipOwnerOrNoOwner(entityId);
    FFMetadata.deleteRecord(entityId);
  }
}
