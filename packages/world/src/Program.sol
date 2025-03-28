// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { ObjectTypeId } from "./ObjectTypeId.sol";
import { ObjectAmount } from "./ObjectTypeLib.sol";
import { EntityId } from "./EntityId.sol";

// All entities
interface IProgram {
  function isSetProgramAllowed(
    EntityId caller,
    EntityId target,
    ResourceId program,
    bytes memory extraData
  ) external view returns (bool);

  // tbd
  function isHookAllowed(EntityId caller, EntityId target, bytes4 selector) external view returns (bool);
}

/**
 * caller is the entity that called the system and triggered the hook
 * target is the entity for which the hook is being called
 */
interface IHooks {
  function onSetProgram(
    EntityId caller,
    EntityId target, // can be the program or the forcefield
    EntityId programmed,
    ResourceId program,
    bytes memory extraData
  ) external returns (bool);

  // Entities with inventory
  function onTransfer(
    EntityId caller,
    EntityId target,
    EntityId from,
    EntityId to,
    ObjectAmount[] objectAmounts,
    EntityId[] toolEntities,
    bytes memory extraData
  ) external returns (bool);

  // Machines
  function onHit(EntityId caller, EntityId target, uint128 damage, bytes memory extraData) external;

  function onFuel(EntityId caller, EntityId target, uint16 fuelAmount, bytes memory extraData) external returns (bool);

  // Forcefield
  function onAddFragment(
    EntityId caller,
    EntityId target,
    EntityId added,
    bytes memory extraData
  ) external returns (bool);

  function onRemoveFragment(
    EntityId caller,
    EntityId target,
    EntityId removed,
    bytes memory extraData
  ) external returns (bool);

  // Forcefield & Fragment
  function onBuild(
    EntityId caller,
    EntityId target,
    ObjectTypeId objectTypeId,
    Vec3 coord,
    bytes memory extraData
  ) external payable;

  function onMine(
    EntityId caller,
    EntityId target,
    ObjectTypeId objectTypeId,
    Vec3 coord,
    bytes memory extraData
  ) external payable;

  // Spawn tile
  function onSpawn(EntityId caller, EntityId target, bytes memory extraData) external returns (bool);

  // Bed
  function onSleep(EntityId caller, EntityId target, bytes memory extraData) external returns (bool);

  function onWakeup(EntityId caller, EntityId target, bytes memory extraData) external returns (bool);

  // Door
  function onOpen(EntityId caller, EntityId target, bytes memory extraData) external returns (bool);

  function onClose(EntityId caller, EntityId target, bytes memory extraData) external returns (bool);

  // Displays
  // TODO: describe format
  function getDisplayURI(EntityId caller, EntityId target) external view returns (string memory);
}
