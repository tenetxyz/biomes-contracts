// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { CountdownData } from "./../tables/Countdown.sol";

/**
 * @title ICountdownSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface ICountdownSystem {
  function experience__setCountdown(CountdownData memory countdownData) external;

  function experience__setCountdownEndTimestamp(uint256 countdownEndTimestamp) external;

  function experience__setCountdownEndBlock(uint256 countdownEndBlock) external;

  function experience__deleteCountdown() external;
}
