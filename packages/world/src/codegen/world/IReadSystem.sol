// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { VoxelCoord, EntityData, InventoryObject } from "../../Types.sol";

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

  function getObjectTypeIdAtCoord(VoxelCoord memory coord) external view returns (uint16);

  function getEntityIdAtCoord(VoxelCoord memory coord) external view returns (bytes32);

  function getEntityData(bytes32 entityId) external view returns (EntityData memory);

  function getEntityDataAtCoord(VoxelCoord memory coord) external view returns (EntityData memory);

  function getMultipleEntityDataAtCoord(VoxelCoord[] memory coord) external view returns (EntityData[] memory);

  function getLastActivityTime(address player) external view returns (uint256);

  function getInventory(address player) external view returns (InventoryObject[] memory);

  function getInventory(bytes32 entityId) external view returns (InventoryObject[] memory);

  function getCoordForEntityId(bytes32 entityId) external view returns (VoxelCoord memory);

  function getPlayerCoord(address player) external view returns (VoxelCoord memory);
}
