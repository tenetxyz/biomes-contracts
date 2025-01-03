// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { BlockExperienceEntityData, BlockExperienceEntityDataWithGateApprovals, BlockExperienceEntityDataWithExchanges } from "./../../Types.sol";

/**
 * @title IReadSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IReadSystem {
  function experience__getBlockEntityData(bytes32 entityId) external view returns (BlockExperienceEntityData memory);

  function experience__getBlockEntityDataWithGateApprovals(
    bytes32 entityId
  ) external view returns (BlockExperienceEntityDataWithGateApprovals memory);

  function experience__getBlockEntityDataWithExchanges(
    bytes32 entityId
  ) external view returns (BlockExperienceEntityDataWithExchanges memory);

  function experience__getBlocksEntityData(
    bytes32[] memory entityIds
  ) external view returns (BlockExperienceEntityData[] memory);

  function experience__getBlocksEntityDataWithGateApprovals(
    bytes32[] memory entityIds
  ) external view returns (BlockExperienceEntityDataWithGateApprovals[] memory);

  function experience__getBlocksEntityDataWithExchanges(
    bytes32[] memory entityIds
  ) external view returns (BlockExperienceEntityDataWithExchanges[] memory);
}
