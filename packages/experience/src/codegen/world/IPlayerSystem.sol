// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

/**
 * @title IPlayerSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IPlayerSystem {
  function experience__setPlayers(address[] memory players) external;

  function experience__pushPlayers(address player) external;

  function experience__popPlayers() external;

  function experience__updatePlayers(uint256 index, address player) external;

  function experience__deletePlayers() external;
}