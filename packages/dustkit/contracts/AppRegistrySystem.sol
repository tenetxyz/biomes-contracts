// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { AppRegistry } from "./codegen/tables/AppRegistry.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";
import { System } from "@latticexyz/world/src/System.sol";

contract AppRegistrySystem is System {
  function registerApp(ResourceId appId, string memory appConfigUrl) public {
    AccessControl.requireOwner(appId, _msgSender());
    AppRegistry.set(appId, appConfigUrl);
  }
}
