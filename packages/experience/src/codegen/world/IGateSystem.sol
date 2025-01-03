// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { GateApprovalsData } from "./../tables/GateApprovals.sol";

/**
 * @title IGateSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IGateSystem {
  function experience__setGateApprovals(bytes32 entityId, GateApprovalsData memory approvals) external;

  function experience__deleteGateApprovals(bytes32 entityId) external;

  function experience__setGateApprovedPlayers(bytes32 entityId, address[] memory players) external;

  function experience__pushGateApprovedPlayer(bytes32 entityId, address player) external;

  function experience__popGateApprovedPlayer(bytes32 entityId) external;

  function experience__updateGateApprovedPlayer(bytes32 entityId, uint256 index, address player) external;

  function experience__setGateApprovedNFT(bytes32 entityId, address[] memory nfts) external;

  function experience__pushGateApprovedNFT(bytes32 entityId, address nft) external;

  function experience__popGateApprovedNFT(bytes32 entityId) external;

  function experience__updateGateApprovedNFT(bytes32 entityId, uint256 index, address nft) external;
}
