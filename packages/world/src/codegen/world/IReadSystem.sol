// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { HealthData } from "./../tables/Health.sol";
import { StaminaData } from "./../tables/Stamina.sol";

/**
 * @title IReadSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IReadSystem {
  function getOptionalSystemHooks(
    address player,
    ResourceId SystemId,
    bytes32 callDataHash
  ) external view returns (bytes21[] memory hooks);

  function getUserDelegation(
    address delegator,
    address delegatee
  ) external view returns (ResourceId delegationControlId);

  function getObjectTypeIdAtCoord(VoxelCoord memory coord) external view returns (uint8);

  function getObjectTypeIdAtCoordOrTerrain(VoxelCoord memory coord) external view returns (uint8);

  function getEntityIdAtCoord(VoxelCoord memory coord) external view returns (bytes32);

  function getLastActivityTime(address player) external view returns (uint256);

  function getHealth(address player) external view returns (HealthData memory);

  function getStamina(address player) external view returns (StaminaData memory);
}
