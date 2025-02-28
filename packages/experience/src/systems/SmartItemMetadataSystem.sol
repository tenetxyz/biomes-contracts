// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { EntityId } from "@biomesaw/world/src/EntityId.sol";

import { IWorld } from "../codegen/world/IWorld.sol";
import { SmartItemMetadata, SmartItemMetadataData } from "../codegen/tables/SmartItemMetadata.sol";
import { requireChipOwner, requireChipOwnerOrNoOwner } from "../Utils.sol";

contract SmartItemMetadataSystem is System {
  function setSmartItemMetadata(EntityId entityId, SmartItemMetadataData memory metadata) public {
    requireChipOwner(entityId);
    SmartItemMetadata.set(entityId, metadata);
  }

  function setSmartItemName(EntityId entityId, string memory name) public {
    requireChipOwner(entityId);
    SmartItemMetadata.setName(entityId, name);
  }

  function setSmartItemDescription(EntityId entityId, string memory description) public {
    requireChipOwner(entityId);
    SmartItemMetadata.setDescription(entityId, description);
  }

  function deleteSmartItemMetadata(EntityId entityId) public {
    requireChipOwnerOrNoOwner(entityId);
    SmartItemMetadata.deleteRecord(entityId);
  }
}
