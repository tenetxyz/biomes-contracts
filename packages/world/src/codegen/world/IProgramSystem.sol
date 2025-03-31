// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { EntityId } from "../../EntityId.sol";
import { ProgramId } from "../../ProgramId.sol";

/**
 * @title IProgramSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IProgramSystem {
  function attachProgram(
    EntityId caller,
    EntityId target,
    ProgramId program,
    bytes calldata extraData
  ) external payable;

  function detachProgram(EntityId caller, EntityId target, bytes calldata extraData) external payable;
}
