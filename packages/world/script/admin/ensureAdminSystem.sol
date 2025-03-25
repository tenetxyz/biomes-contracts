// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../src/codegen/world/IWorld.sol";

import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { ROOT_NAMESPACE } from "@latticexyz/world/src/constants.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { AdminSystem } from "../../src/systems/admin/AdminSystem.sol";

function ensureAdminSystem(IWorld world) {
  ResourceId adminSystemId = WorldResourceIdLib.encode({
    typeId: RESOURCE_SYSTEM,
    namespace: ROOT_NAMESPACE,
    name: "AdminSystem"
  });
  address existingAdminSystem = Systems.getSystem(adminSystemId);
  if (existingAdminSystem != address(0)) {
    return;
  }
  AdminSystem adminSystem = new AdminSystem();
  world.registerSystem(adminSystemId, adminSystem, true);

  world.registerRootFunctionSelector(
    adminSystemId,
    "adminAddToInventory(bytes32,uint16,uint16)",
    "adminAddToInventory(bytes32,uint16,uint16)"
  );
  world.registerRootFunctionSelector(
    adminSystemId,
    "adminAddToolToInventory(bytes32,uint16)",
    "adminAddToolToInventory(bytes32,uint16)"
  );
  world.registerRootFunctionSelector(
    adminSystemId,
    "adminRemoveFromInventory(bytes32,uint16,uint16)",
    "adminRemoveFromInventory(bytes32,uint16,uint16)"
  );
  world.registerRootFunctionSelector(
    adminSystemId,
    "adminRemoveToolFromInventory(bytes32,bytes32)",
    "adminRemoveToolFromInventory(bytes32,bytes32)"
  );
}
