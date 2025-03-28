// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;
import { IProgram } from "./IProgram.sol";
import { EntityId } from "../EntityId.sol";
import { ObjectAmount } from "../ObjectTypeLib.sol";

//
// // Interface for a force field program
// interface IOnSleep is IProgram {
//   function onSleep(EntityId callerEntityId, EntityId bedEntityId, bytes memory extraData) external payable;
// }
//
// interface IOnWakeUp is IProgram {
//   function onWakeup(EntityId callerEntityId, EntityId bedEntityId, bytes memory extraData) external payable;
// }
//
// type Hook is bytes4;
//
// Hook constant onSleep = Hook.wrap(IOnSleep.onSleep.selector);
//
// contract Program is WorldConsumer(DUST_WORLD) {
//
// }
//
// contract CityProgram is Program {
//   function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
//     // ...
//   }
//
//   function onProgramAttached(EntityId caller, EntityId target, bytes memory extraData) external payable {
//     auth(caller, target);
//
//     require(isProgramAllowed(target.getProgram()), "Program not allowed");
//   }
//
//   function onProgramDetached(EntityId caller, EntityId target, bytes memory extraData) external payable {
//     auth(caller, target);
//   }
// }
//
// contract ShopProgram is Program {
//   function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
//     // ...
//   }
//
//   function onAttached(EntityId caller, EntityId target, bytes memory extraData) external onlyWorld {
//     auth(caller, target);
//     requireChest(target);
//     (string memory name) = abi.decode(extraData, (string));
//     createShop(target, caller, name);
//   }
//
//   function onDetached(EntityId caller, EntityId target, bytes memory extraData) external onlyWorld {
//     auth(caller, target);
//     deleteShop(target);
//   }
//
//   function onTransfer(ProgramOnTransferData memory transferContext) external onlyWorld {
//     processTrade(transferContext);
//   }
//
//   // ...
// }
//
// contract PrivateChest is Program {
//   function supportsInterface(bytes4 interfaceId) returns (bool) {
//     // ...
//   }
//
//   function onAttached(EntityId caller, EntityId target, bytes memory extraData) external onlyWorld {
//     requireChest(target);
//     setAllowed(caller, target);
//   }
//
//   function onDetached(EntityId caller, EntityId target, bytes memory extraData) external onlyWorld {
//     requireAllowed(caller, target);
//   }
//
//   function onTransfer(EntityId caller, EntityId target, ...) external onlyWorld {
//     requireAllowed(caller, target);
//   }
// }
//
//
// type Hooks is uint256;
//
// contract PrivateChest is Program {
//
//   function onAttached(EntityId caller, EntityId target, bytes memory extraData) external onlyWorld {
//     requireChest(target);
//     setAllowed(caller, target);
//   }
//
//   function onDetached(EntityId caller, EntityId target, bytes memory extraData) external onlyWorld {
//     requireAllowed(caller, target);
//   }
//
//   function onTransfer(EntityId caller, EntityId target, ...) external onlyWorld {
//     requireAllowed(caller, target);
//   }
//
//   // ...
// }
//
interface IHooks {
  struct TransferData {
    ObjectAmount[] objectAmounts;
    EntityId[] entities;
  }

  // All programs
  function onAttached(EntityId caller, EntityId target, bytes memory extraData) external returns (bool);

  function onDetached(EntityId caller, EntityId target, bytes memory extraData) external returns (bool);

  // Inventory
  function onTransfer(
    EntityId caller,
    EntityId target,
    EntityId from,
    EntityId to,
    TransferData memory transferData,
    bytes memory extraData
  ) external returns (bool);

  // Machines
  function onFueled(
    EntityId caller,
    EntityId target,
    uint16 fuelAmount,
    bytes memory extraData
  ) external returns (bool);

  function onHit(EntityId caller, EntityId target, uint128 damage, bytes memory extraData) external returns (bool);

  function onInteract(EntityId caller, EntityId target, bytes memory extraData) external payable;

  // Forcefield
  function onAdd(EntityId caller, EntityId target, EntityId added, bytes memory extraData) external payable;

  function onRemove(EntityId caller, EntityId target, EntityId removed, bytes memory extraData) external payable;

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

  function onProgramAttached(
    EntityId caller,
    EntityId target,
    EntityId attachedTo,
    bytes memory extraData
  ) external returns (bool);

  function onProgramDetached(
    EntityId caller,
    EntityId target,
    EntityId detachedFrom,
    bytes memory extraData
  ) external returns (bool);

  // TODO: Should we just remove these in favor of onInteract()?
  function onSpawn(EntityId caller, EntityId target, bytes memory extraData) external payable;

  function onSleep(EntityId caller, EntityId target, bytes memory extraData) external payable;

  function onWakeup(EntityId caller, EntityId target, bytes memory extraData) external payable;

  // View functions
  function getDisplay(EntityId caller, EntityId target) external view returns (bytes memory);
}
