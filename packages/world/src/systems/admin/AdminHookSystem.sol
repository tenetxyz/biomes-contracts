// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";
import { ROOT_NAMESPACE_ID } from "@latticexyz/world/src/constants.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { OptionalSystemHooks } from "@latticexyz/world/src/codegen/tables/OptionalSystemHooks.sol";
import { IOptionalSystemHook } from "@latticexyz/world/src/IOptionalSystemHook.sol";
import { Hook } from "@latticexyz/store/src/Hook.sol";

contract AdminHookSystem is System {
  function deleteAllUserHooks(address player, ResourceId systemId, bytes32 callDataHash) public {
    AccessControl.requireOwner(ROOT_NAMESPACE_ID, _msgSender());
    bytes21[] memory currentHooks = OptionalSystemHooks._get(player, systemId, callDataHash);
    if (currentHooks.length == 0) {
      return;
    }

    for (uint256 i; i < currentHooks.length; i++) {
      Hook hook = Hook.wrap(currentHooks[i]);
      IOptionalSystemHook(hook.getAddress()).onUnregisterHook(player, systemId, hook.getBitmap(), callDataHash);
    }

    OptionalSystemHooks._deleteRecord(player, systemId, callDataHash);
  }
}
