// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ROOT_NAMESPACE_ID } from "@latticexyz/world/src/constants.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";

import { InitialEnergyPool, LocalEnergyPool } from "../../utils/Vec3Storage.sol";
import { Vec3 } from "../../Vec3.sol";
import { PHYSICS_ORACLE_ADDRESS } from "../../Constants.sol";

contract OracleSystem is System {
  function setInitialEnergyPool(Vec3 shardCoord, uint128 energy) public {
    address namespaceOwner = NamespaceOwner.get(ROOT_NAMESPACE_ID);
    require(
      _msgSender() == PHYSICS_ORACLE_ADDRESS || _msgSender() == namespaceOwner,
      "Only the physics oracle can set the initial energy pool"
    );
    require(shardCoord.y() == 0, "Energy pool chunks are 2D only");
    InitialEnergyPool.set(shardCoord, energy);
    LocalEnergyPool.set(shardCoord, energy);
  }
}
