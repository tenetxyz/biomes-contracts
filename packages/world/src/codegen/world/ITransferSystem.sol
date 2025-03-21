// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { EntityId } from "../../EntityId.sol";
import { ObjectTypeId } from "../../ObjectTypeId.sol";

/**
 * @title ITransferSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface ITransferSystem {
  function transfer(
    EntityId chestEntityId,
    bool isDeposit,
    ObjectTypeId transferObjectTypeId,
    uint16 numToTransfer,
    bytes calldata extraData
  ) external payable;

  function transferTool(
    EntityId chestEntityId,
    bool isDeposit,
    EntityId toolEntityId,
    bytes calldata extraData
  ) external payable;

  function transferTools(
    EntityId chestEntityId,
    bool isDeposit,
    EntityId[] memory toolEntityIds,
    bytes calldata extraData
  ) external payable;
}
