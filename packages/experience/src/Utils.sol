// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { SystemRegistry } from "@latticexyz/world/src/codegen/tables/SystemRegistry.sol";
import { ResourceId, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";

import { NamespaceMetadata } from "./codegen/tables/NamespaceMetadata.sol";

function getExperienceAddress(address msgSender) view returns (address) {
  ResourceId callerSystemId = SystemRegistry.get(msgSender);
  if (ResourceId.unwrap(callerSystemId) == bytes32(0)) {
    return msgSender;
  }

  bytes14 callerNamespace = WorldResourceIdInstance.getNamespace(callerSystemId);
  if (callerNamespace == bytes14(0)) {
    return msgSender;
  }

  address experienceAddress = NamespaceMetadata.getExperience(callerNamespace);
  require(experienceAddress != address(0), "Experience address not found for namespace");
  return experienceAddress;
}
