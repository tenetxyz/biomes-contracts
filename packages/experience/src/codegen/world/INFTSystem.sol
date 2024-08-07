// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

/**
 * @title INFTSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface INFTSystem {
  function experience__setNfts(address[] memory nfts) external;

  function experience__pushNfts(address nft) external;

  function experience__popNfts() external;

  function experience__updateNfts(uint256 index, address nft) external;

  function experience__deleteNfts() external;
}
