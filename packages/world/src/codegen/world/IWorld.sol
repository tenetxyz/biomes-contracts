// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";

import { IActivateSystem } from "./IActivateSystem.sol";
import { IBuildSystem } from "./IBuildSystem.sol";
import { IChipSystem } from "./IChipSystem.sol";
import { ICraftSystem } from "./ICraftSystem.sol";
import { IDropSystem } from "./IDropSystem.sol";
import { IEquipSystem } from "./IEquipSystem.sol";
import { IHitChipSystem } from "./IHitChipSystem.sol";
import { IHitSystem } from "./IHitSystem.sol";
import { ILoginSystem } from "./ILoginSystem.sol";
import { ILogoffSystem } from "./ILogoffSystem.sol";
import { IMineSystem } from "./IMineSystem.sol";
import { IMoveSystem } from "./IMoveSystem.sol";
import { IPickupSystem } from "./IPickupSystem.sol";
import { ISpawnSystem } from "./ISpawnSystem.sol";
import { ITransferSystem } from "./ITransferSystem.sol";
import { IUnequipSystem } from "./IUnequipSystem.sol";
import { IXPSystem } from "./IXPSystem.sol";
import { IAdminHookSystem } from "./IAdminHookSystem.sol";
import { IAdminSpawnSystem } from "./IAdminSpawnSystem.sol";
import { IAdminTerrainSystem } from "./IAdminTerrainSystem.sol";
import { IInitSpawnSystem } from "./IInitSpawnSystem.sol";
import { IProcGenSystem } from "./IProcGenSystem.sol";
import { IReadSystem } from "./IReadSystem.sol";
import { ITerrainSystem } from "./ITerrainSystem.sol";
import { IInitDyedBlocksSystem } from "./IInitDyedBlocksSystem.sol";
import { IInitHandBlocksSystem } from "./IInitHandBlocksSystem.sol";
import { IInitInteractablesSystem } from "./IInitInteractablesSystem.sol";
import { IInitPlayersSystem } from "./IInitPlayersSystem.sol";
import { IInitTerrainBlocksSystem } from "./IInitTerrainBlocksSystem.sol";
import { IInitThermoblastSystem } from "./IInitThermoblastSystem.sol";
import { IInitWorkbenchSystem } from "./IInitWorkbenchSystem.sol";
import { IForceFieldSystem } from "./IForceFieldSystem.sol";
import { IGravitySystem } from "./IGravitySystem.sol";
import { IChestSystem } from "./IChestSystem.sol";

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
  IBuildSystem,
  IChipSystem,
  ICraftSystem,
  IDropSystem,
  IEquipSystem,
  IHitChipSystem,
  IHitSystem,
  ILoginSystem,
  ILogoffSystem,
  IMineSystem,
  IMoveSystem,
  IPickupSystem,
  ISpawnSystem,
  ITransferSystem,
  IUnequipSystem,
  IXPSystem,
  IAdminHookSystem,
  IAdminSpawnSystem,
  IAdminTerrainSystem,
  IInitSpawnSystem,
  IProcGenSystem,
  IReadSystem,
  ITerrainSystem,
  IInitDyedBlocksSystem,
  IInitHandBlocksSystem,
  IInitInteractablesSystem,
  IInitPlayersSystem,
  IInitTerrainBlocksSystem,
  IInitThermoblastSystem,
  IInitWorkbenchSystem,
  IForceFieldSystem,
  IGravitySystem,
  IChestSystem
{}
