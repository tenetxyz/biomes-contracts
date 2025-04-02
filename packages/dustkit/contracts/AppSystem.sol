// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { App } from "./codegen/tables/App.sol";
import { ProgramEntity } from "./codegen/tables/ProgramEntity.sol";
import { EntityId } from "@dust/world/src/EntityId.sol";
import { ProgramId } from "@dust/world/src/ProgramId.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";
import { System } from "@latticexyz/world/src/System.sol";

contract AppSystem is System {
  function registerApp(ResourceId app, string memory configUrl) public {
    AccessControl.requireOwner(app, _msgSender());
    App.set(app, configUrl);
  }

  function setDefaultApp(ProgramId program, ResourceId defaultApp) public {
    require(bytes(App.getConfigUrl(defaultApp)).length != 0, "App not registered.");
    AccessControl.requireOwner(program.toResourceId(), _msgSender());
    ProgramEntity.set(program, EntityId.wrap(0), defaultApp);
  }

  function setDefaultApp(ProgramId program, EntityId entity, ResourceId defaultApp) public {
    require(bytes(App.getConfigUrl(defaultApp)).length != 0, "App not registered.");
    // TODO: how should we permission this?
    ProgramEntity.set(program, entity, defaultApp);
  }
}
