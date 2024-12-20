// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";

import { NamespaceId } from "../codegen/tables/NamespaceId.sol";

contract NamespaceIdSystem is System {
  function setNamespaceId(ResourceId namespaceId) public {
    NamespaceId.set(_msgSender(), namespaceId);
  }

  function deleteNamespaceId() public {
    NamespaceId.deleteRecord(_msgSender());
  }
}
