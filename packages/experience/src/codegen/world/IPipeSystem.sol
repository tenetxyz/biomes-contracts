// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

/**
 * @title IPipeSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IPipeSystem {
  function experience__setPipeAccess(
    bytes32 targetEntityId,
    bytes32 callerEntityId,
    bool depositAllowed,
    bool withdrawAllowed
  ) external;

  function experience__setPipeRouting(bytes32 sourceEntityId, bytes32 targetEntityId, bool enabled) external;

  function experience__deletePipeAccess(bytes32 targetEntityId, bytes32 callerEntityId) external;

  function experience__deletePipeRouting(bytes32 sourceEntityId, bytes32 targetEntityId) external;

  function experience__deletePipeAccessList(bytes32 targetEntityId) external;

  function experience__deletePipeRoutingList(bytes32 sourceEntityId) external;
}