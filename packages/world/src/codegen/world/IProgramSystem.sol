// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { EntityId } from "../../EntityId.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";

/**
 * @title IProgramSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IProgramSystem {
  function attachProgram(
    EntityId callerEntityId,
    EntityId targetEntityId,
    ResourceId programSystemId,
    bytes calldata extraData
  ) external payable;

  function detachProgram(EntityId callerEntityId, EntityId targetEntityId, bytes calldata extraData) external payable;
}
