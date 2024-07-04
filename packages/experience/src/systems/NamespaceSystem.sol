// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { SystemRegistry } from "@latticexyz/world/src/codegen/tables/SystemRegistry.sol";
import { ResourceId, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";

import { NamespaceMetadata } from "../codegen/tables/NamespaceMetadata.sol";
import { getCallerNamespace } from "@biomesaw/utils/src/CallUtils.sol";

contract NamespaceSystem is System {
  function setNamespaceExperience(address experience) public {
    bytes14 callerNamespace = getCallerNamespace(_msgSender());
    require(callerNamespace != bytes14(0), "NamespaceSystem: Caller is not in a namespace.");
    NamespaceMetadata.setExperience(callerNamespace, experience);
  }

  function deleteNamespaceExperience() public {
    bytes14 callerNamespace = getCallerNamespace(_msgSender());
    require(callerNamespace != bytes14(0), "NamespaceSystem: Caller is not in a namespace.");
    NamespaceMetadata.deleteRecord(callerNamespace);
  }
}
