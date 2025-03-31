// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { EntityId } from "./EntityId.sol";
import { Vec3 } from "./Vec3.sol";
import { ObjectTypeId } from "./ObjectTypeId.sol";
import { ObjectAmount } from "./ObjectTypeLib.sol";

/**
 * caller is the entity that called the system and triggered the hook
 * target is the entity for which the hook is being called
 */
interface IHooks {
  function onAttachProgram(EntityId caller, EntityId target, bytes memory extraData) external;

  function onDetachProgram(EntityId caller, EntityId target, bytes memory extraData) external;

  // Entities with inventory
  function onTransfer(
    EntityId caller,
    EntityId target,
    EntityId from,
    EntityId to,
    ObjectAmount[] memory objectAmounts,
    EntityId[] memory toolEntities,
    bytes memory extraData
  ) external;

  // Machines
  function onHit(EntityId caller, EntityId target, uint128 damage, bytes memory extraData) external;

  function onFuel(EntityId caller, EntityId target, uint16 fuelAmount, bytes memory extraData) external;

  // Forcefield
  function onAddFragment(EntityId caller, EntityId target, EntityId added, bytes memory extraData) external;

  function onRemoveFragment(EntityId caller, EntityId target, EntityId removed, bytes memory extraData) external;

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
  function onSpawn(EntityId caller, EntityId target, bytes memory extraData) external;

  // Bed
  function onSleep(EntityId caller, EntityId target, bytes memory extraData) external;

  function onWakeup(EntityId caller, EntityId target, bytes memory extraData) external;

  // Door
  function onOpen(EntityId caller, EntityId target, bytes memory extraData) external;

  function onClose(EntityId caller, EntityId target, bytes memory extraData) external;
}
