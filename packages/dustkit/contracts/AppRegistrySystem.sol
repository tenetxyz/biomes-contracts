// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { AppRegistry } from "./codegen/tables/AppRegistry.sol";
import { AccessControl } from "@latticexyz/store/src/AccessControl.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { System } from "@latticexyz/world/src/System.sol";

contract AppRegistrySystem is System {
  function registerApp(ResourceId appId, string memory appConfigUrl) public {
    AccessControl.requireOwner(appId);
    AppRegistry.set(appId, appConfigUrl);
  }
}
