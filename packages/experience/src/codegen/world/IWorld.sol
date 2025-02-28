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
  ITokenMetadataSystem
{}
