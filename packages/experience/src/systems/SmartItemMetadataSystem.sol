// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { SmartItemMetadata, SmartItemMetadataData } from "../codegen/tables/SmartItemMetadata.sol";
import { requireChipOwner, requireChipOwnerOrNoOwner } from "../Utils.sol";

contract SmartItemMetadataSystem is System {
  function setSmartItemMetadata(bytes32 entityId, SmartItemMetadataData memory metadata) public {
    requireChipOwner(entityId);
    SmartItemMetadata.set(entityId, metadata);
  }

  function setSmartItemName(bytes32 entityId, string memory name) public {
    requireChipOwner(entityId);
    SmartItemMetadata.setName(entityId, name);
  }

  function setSmartItemDescription(bytes32 entityId, string memory description) public {
    requireChipOwner(entityId);
    SmartItemMetadata.setDescription(entityId, description);
  }

  function deleteSmartItemMetadata(bytes32 entityId) public {
    requireChipOwnerOrNoOwner(entityId);
    SmartItemMetadata.deleteRecord(entityId);
  }
}
