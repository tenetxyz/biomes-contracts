// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { IAssetsSystem } from "./IAssetsSystem.sol";
import { IChipAdminSystem } from "./IChipAdminSystem.sol";
import { IChipAttachmentSystem } from "./IChipAttachmentSystem.sol";
import { IChipMetadataSystem } from "./IChipMetadataSystem.sol";
import { IExchangeNotifSystem } from "./IExchangeNotifSystem.sol";
import { IExchangeSystem } from "./IExchangeSystem.sol";
import { IGateSystem } from "./IGateSystem.sol";
import { INFTMetadataSystem } from "./INFTMetadataSystem.sol";
import { INamespaceIdSystem } from "./INamespaceIdSystem.sol";
import { INotificationSystem } from "./INotificationSystem.sol";
import { IPipeSystem } from "./IPipeSystem.sol";
import { IReadSystem } from "./IReadSystem.sol";
import { ISmartItemMetadataSystem } from "./ISmartItemMetadataSystem.sol";
import { ITokenMetadataSystem } from "./ITokenMetadataSystem.sol";
import { IAreaSystem } from "./IAreaSystem.sol";
import { IBuildsSystem } from "./IBuildsSystem.sol";
import { IChestMetadataSystem } from "./IChestMetadataSystem.sol";
import { IChipNamespaceSystem } from "./IChipNamespaceSystem.sol";
import { ICountdownSystem } from "./ICountdownSystem.sol";
import { IDisplaySystem } from "./IDisplaySystem.sol";
import { IExpMetadataSystem } from "./IExpMetadataSystem.sol";
import { IFFApprovalsSystem } from "./IFFApprovalsSystem.sol";
import { IFFMetadataSystem } from "./IFFMetadataSystem.sol";
import { IItemShopNotifSystem } from "./IItemShopNotifSystem.sol";
import { INFTSystem } from "./INFTSystem.sol";
import { IPlayerSystem } from "./IPlayerSystem.sol";
import { IShopSystem } from "./IShopSystem.sol";
import { ITokenSystem } from "./ITokenSystem.sol";

/**
 * @title IWorld
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @notice This interface integrates all systems and associated function selectors
 * that are dynamically registered in the World during deployment.
 * @dev This is an autogenerated file; do not edit manually.
 */
interface IWorld is
  IBaseWorld,
  IAssetsSystem,
  IChipAdminSystem,
  IChipAttachmentSystem,
  IChipMetadataSystem,
  IExchangeNotifSystem,
  IExchangeSystem,
  IGateSystem,
  INFTMetadataSystem,
  INamespaceIdSystem,
  INotificationSystem,
  IPipeSystem,
  IReadSystem,
  ISmartItemMetadataSystem,
  ITokenMetadataSystem,
  IAreaSystem,
  IBuildsSystem,
  IChestMetadataSystem,
  IChipNamespaceSystem,
  ICountdownSystem,
  IDisplaySystem,
  IExpMetadataSystem,
  IFFApprovalsSystem,
  IFFMetadataSystem,
  IItemShopNotifSystem,
  INFTSystem,
  IPlayerSystem,
  IShopSystem,
  ITokenSystem
{}
