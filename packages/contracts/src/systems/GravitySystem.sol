// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";

import { Position, PositionData } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Inventory } from "../codegen/tables/Inventory.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Health, HealthData } from "../codegen/tables/Health.sol";
import { Stamina, StaminaData } from "../codegen/tables/Stamina.sol";

import { VoxelCoord } from "@everlonxyz/utils/src/Types.sol";
import { GRAVITY_DAMAGE } from "../Constants.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID } from "../ObjectTypeIds.sol";
import { applyGravity } from "../utils/GravityUtils.sol";

// Note: this is a simple system that only calls the gravity util function
// it's in a separate system for contracts that reach the max contract size (eg MineSystem)
contract GravitySystem is System {
  function runGravity(bytes32 playerEntityId, VoxelCoord memory coord) public returns (bool) {
    return applyGravity(playerEntityId, coord);
  }
}
