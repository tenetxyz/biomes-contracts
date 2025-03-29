// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { ObjectTypeId } from "./ObjectTypeId.sol";
import { ObjectAmount } from "./ObjectTypeLib.sol";
import { EntityId } from "./EntityId.sol";
import { Vec3 } from "./Vec3.sol";

type ProgramId is bytes32;

/**
 * caller is the entity that called the system and triggered the hook
 * target is the entity for which the hook is being called
 */
interface IHooks {
  function isProgramAllowed(
    EntityId caller,
    EntityId target,
    EntityId programmed,
    ProgramId newProgram,
    bytes memory extraData
  ) external view returns (bool);

  function onAttachProgram(EntityId caller, EntityId target, bytes memory extraData) external returns (bool);

  function onDetachProgram(EntityId caller, EntityId target, bytes memory extraData) external returns (bool);

  // Entities with inventory
  function onTransfer(
    EntityId caller,
    EntityId target,
    EntityId from,
    EntityId to,
    ObjectAmount[] memory objectAmounts,
    EntityId[] memory toolEntities,
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

library ProgramIdLib {
  function exists(ProgramId self) internal pure returns (bool) {
    return ProgramId.unwrap(self) != 0;
  }

  function toResourceId(ProgramId self) internal pure returns (ResourceId) {
    return ResourceId.wrap(ProgramId.unwrap(self));
  }

  function getAddress(ProgramId self) internal view returns (address) {
    (address programAddress, ) = Systems._get(self.toResourceId());
    return programAddress;
  }

  function isProgramAllowed(
    ProgramId self,
    EntityId caller,
    EntityId target,
    EntityId programmed,
    ProgramId newProgram,
    bytes memory extraData
  ) internal view returns (bool) {
    bytes memory data = abi.encodeCall(IHooks.isProgramAllowed, (caller, target, programmed, newProgram, extraData));
    (bool success, bytes memory returnData) = staticcallHook(self, data);
  }

  function onAttachProgram(ProgramId self, EntityId caller, EntityId target, bytes memory extraData) internal {
    bytes memory data = abi.encodeCall(IHooks.onAttachProgram, (caller, target, extraData));
    (bool success, bytes memory returnData) = callHook(self, data);
    require(success && abi.decode(returnData, (bool)));
    // if (success) return abi.decode(returnData, (bool));
  }

  function onDetachProgram(
    ProgramId self,
    EntityId caller,
    EntityId target,
    // TODO: should we include previous contract?
    bytes memory extraData
  ) internal {}

  // Entities with inventory
  function onTransfer(
    ProgramId self,
    EntityId caller,
    EntityId target,
    EntityId from,
    EntityId to,
    ObjectAmount[] memory objectAmounts,
    EntityId[] memory toolEntities,
    bytes memory extraData
  ) external returns (bool) {}

  // Machines
  function onHit(ProgramId self, EntityId caller, EntityId target, uint128 damage, bytes memory extraData) internal {}

  function onFuel(
    ProgramId self,
    EntityId caller,
    EntityId target,
    uint16 fuelAmount,
    bytes memory extraData
  ) internal returns (bool) {}

  // Forcefield
  function onAddFragment(
    ProgramId self,
    EntityId caller,
    EntityId target,
    EntityId added,
    bytes memory extraData
  ) internal returns (bool) {}

  function onRemoveFragment(
    ProgramId self,
    EntityId caller,
    EntityId target,
    EntityId removed,
    bytes memory extraData
  ) internal returns (bool) {}

  // Forcefield & Fragment
  function onBuild(
    ProgramId self,
    EntityId caller,
    EntityId target,
    ObjectTypeId objectTypeId,
    Vec3 coord,
    bytes memory extraData
  ) internal {}

  function onMine(
    ProgramId self,
    EntityId caller,
    EntityId target,
    ObjectTypeId objectTypeId,
    Vec3 coord,
    bytes memory extraData
  ) internal {}

  // Spawn tile
  function onSpawn(ProgramId self, EntityId caller, EntityId target, bytes memory extraData) internal returns (bool) {}

  // Bed
  function onSleep(ProgramId self, EntityId caller, EntityId target, bytes memory extraData) internal returns (bool) {}

  function onWakeup(ProgramId self, EntityId caller, EntityId target, bytes memory extraData) internal returns (bool) {}

  // Door
  function onOpen(ProgramId self, EntityId caller, EntityId target, bytes memory extraData) internal returns (bool) {}

  function onClose(ProgramId self, EntityId caller, EntityId target, bytes memory extraData) internal returns (bool) {}

  // Displays
  function getDisplayURI(ProgramId self, EntityId caller, EntityId target) internal view returns (string memory) {}
}

using ProgramIdLib for ProgramId global;
