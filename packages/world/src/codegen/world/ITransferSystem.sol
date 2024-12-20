// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

/**
 * @title ITransferSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface ITransferSystem {
  function transfer(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    uint8 transferObjectTypeId,
    uint16 numToTransfer,
    bytes memory extraData
  ) external payable;

  function transferTool(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    bytes32 toolEntityId,
    bytes memory extraData
  ) external payable;

  function transferTools(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    bytes32[] memory toolEntityIds,
    bytes memory extraData
  ) external payable;

  function transfer(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    uint8 transferObjectTypeId,
    uint16 numToTransfer
  ) external payable;

  function transferTool(bytes32 srcEntityId, bytes32 dstEntityId, bytes32 toolEntityId) external payable;

  function transferTools(bytes32 srcEntityId, bytes32 dstEntityId, bytes32[] memory toolEntityIds) external payable;
}
