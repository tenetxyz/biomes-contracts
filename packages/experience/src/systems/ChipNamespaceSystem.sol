// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";

import { ChipNamespace } from "../codegen/tables/ChipNamespace.sol";

contract ChipNamespaceSystem is System {
  function setChipNamespace(ResourceId namespaceId) public {
    ChipNamespace.set(_msgSender(), namespaceId);
  }

  function deleteChipNamespace() public {
    ChipNamespace.deleteRecord(_msgSender());
  }
}
