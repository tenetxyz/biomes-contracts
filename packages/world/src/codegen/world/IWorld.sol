// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { IActivateSystem } from "./IActivateSystem.sol";
import { IBedSystem } from "./IBedSystem.sol";
import { IBucketSystem } from "./IBucketSystem.sol";
import { IBuildSystem } from "./IBuildSystem.sol";
import { IChipSystem } from "./IChipSystem.sol";
import { ICraftSystem } from "./ICraftSystem.sol";
import { IDisplaySystem } from "./IDisplaySystem.sol";
import { IDropSystem } from "./IDropSystem.sol";
import { IEquipSystem } from "./IEquipSystem.sol";
import { IFarmingSystem } from "./IFarmingSystem.sol";
import { IForceFieldSystem } from "./IForceFieldSystem.sol";
import { IHitMachineSystem } from "./IHitMachineSystem.sol";
import { IMachineSystem } from "./IMachineSystem.sol";
import { IMineSystem } from "./IMineSystem.sol";
import { IMoveSystem } from "./IMoveSystem.sol";
import { IOreSystem } from "./IOreSystem.sol";
import { IPickupSystem } from "./IPickupSystem.sol";
import { ISpawnSystem } from "./ISpawnSystem.sol";
import { ITerrainSystem } from "./ITerrainSystem.sol";
import { ITransferSystem } from "./ITransferSystem.sol";
import { IUnequipSystem } from "./IUnequipSystem.sol";
import { IAdminSystem } from "./IAdminSystem.sol";
import { IReadSystem } from "./IReadSystem.sol";
import { IReadTwoSystem } from "./IReadTwoSystem.sol";

/**
 * @title IWorld
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @notice This interface integrates all systems and associated function selectors
 * that are dynamically registered in the World during deployment.
 * @dev This is an autogenerated file; do not edit manually.
 */
interface IWorld is
  IBaseWorld,
  IActivateSystem,
  IBedSystem,
  IBucketSystem,
  IBuildSystem,
  IChipSystem,
  ICraftSystem,
  IDisplaySystem,
  IDropSystem,
  IEquipSystem,
  IFarmingSystem,
  IForceFieldSystem,
  IHitMachineSystem,
  IMachineSystem,
  IMineSystem,
  IMoveSystem,
  IOreSystem,
  IPickupSystem,
  ISpawnSystem,
  ITerrainSystem,
  ITransferSystem,
  IUnequipSystem,
  IAdminSystem,
  IReadSystem,
  IReadTwoSystem
{}
