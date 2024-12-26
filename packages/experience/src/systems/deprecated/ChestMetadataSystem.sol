// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ChestMetadata, ChestMetadataData } from "../../codegen/tables/ChestMetadata.sol";
import { requireChipOwner, requireChipOwnerOrNoOwner } from "../../Utils.sol";

contract ChestMetadataSystem is System {
  function setChestMetadata(bytes32 entityId, ChestMetadataData memory metadata) public {
    requireChipOwner(entityId);
    ChestMetadata.set(entityId, metadata);
  }

  function setChestName(bytes32 entityId, string memory name) public {
    requireChipOwner(entityId);
    ChestMetadata.setName(entityId, name);
  }

  function setChestDescription(bytes32 entityId, string memory description) public {
    requireChipOwner(entityId);
    ChestMetadata.setDescription(entityId, description);
  }

  function deleteChestMetadata(bytes32 entityId) public {
    requireChipOwnerOrNoOwner(entityId);
    ChestMetadata.deleteRecord(entityId);
  }
}
