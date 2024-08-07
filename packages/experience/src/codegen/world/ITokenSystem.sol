// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

/**
 * @title ITokenSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface ITokenSystem {
  function experience__setTokens(address[] memory tokens) external;

  function experience__pushTokens(address token) external;

  function experience__popTokens() external;

  function experience__updateTokens(uint256 index, address token) external;

  function experience__deleteTokens() external;
}
