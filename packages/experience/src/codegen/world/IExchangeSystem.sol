// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { EntityId } from "@biomesaw/world/src/EntityId.sol";
import { ExchangeInfoData } from "../tables/ExchangeInfo.sol";

/**
 * @title IExchangeSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IExchangeSystem {
  function experience__setExchanges(
    EntityId entityId,
    bytes32[] memory exchangeIds,
    ExchangeInfoData[] memory exchangeInfoData
  ) external;

  function experience__addExchange(
    EntityId entityId,
    bytes32 exchangeId,
    ExchangeInfoData memory exchangeInfoData
  ) external;

  function experience__deleteExchange(EntityId entityId, bytes32 exchangeId) external;

  function experience__deleteExchanges(EntityId entityId) external;

  function experience__setExchangeInUnitAmount(EntityId entityId, bytes32 exchangeId, uint256 inUnitAmount) external;

  function experience__setExchangeOutUnitAmount(EntityId entityId, bytes32 exchangeId, uint256 outUnitAmount) external;

  function experience__setExchangeInMaxAmount(EntityId entityId, bytes32 exchangeId, uint256 inMaxAmount) external;

  function experience__setExchangeOutMaxAmount(EntityId entityId, bytes32 exchangeId, uint256 outMaxAmount) external;
}
