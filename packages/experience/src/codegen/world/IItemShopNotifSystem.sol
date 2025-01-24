// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { ItemShopNotifData } from "../tables/ItemShopNotif.sol";

/**
 * @title IItemShopNotifSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IItemShopNotifSystem {
  function experience__emitShopNotif(bytes32 chestEntityId, ItemShopNotifData memory notifData) external;

  function experience__deleteShopNotif(bytes32 chestEntityId) external;
}
