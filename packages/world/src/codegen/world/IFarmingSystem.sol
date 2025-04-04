// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { EntityId } from "../../EntityId.sol";
import { Vec3 } from "../../Vec3.sol";

/**
 * @title IFarmingSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IFarmingSystem {
  function till(EntityId caller, Vec3 coord, EntityId tool) external;

  function growSeed(EntityId caller, Vec3 coord) external;
}
