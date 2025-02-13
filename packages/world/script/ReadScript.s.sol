// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { console } from "forge-std/console.sol";
import { VoxelCoord } from "../src/VoxelCoord.sol";
import { EntityId } from "../src/EntityId.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../src/codegen/tables/InventoryObjects.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { ReversePlayer } from "../src/codegen/tables/ReversePlayer.sol";
import { PlayerStatus } from "../src/codegen/tables/PlayerStatus.sol";
import { Position, PositionData } from "../src/codegen/tables/Position.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { Chip } from "../src/codegen/tables/Chip.sol";
import { ForceField } from "../src/codegen/tables/ForceField.sol";
import { Energy } from "../src/codegen/tables/Energy.sol";

import { positionDataToVoxelCoord } from "../src/Utils.sol";

contract ReadScript is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    EntityId playerEntityId = Player.get(0xE0ae70caBb529336e25FA7a1f036b77ad0089d2a);
    require(playerEntityId.exists(), "Player entity not found");
    console.log("Player");
    console.logBytes32(EntityId.unwrap(playerEntityId));
    console.logBool(PlayerStatus.getIsLoggedOff(playerEntityId));

    // VoxelCoord memory coord = VoxelCoord(150, 1, -160);
    EntityId entityId = EntityId.wrap(0x00000000000000000000000000000000000000000000000000000000002a4960);
    console.log("Entity at position:");
    console.logBytes32(EntityId.unwrap(entityId));
    console.logUint(ObjectType.get(entityId));
    VoxelCoord memory coord = positionDataToVoxelCoord(Position.get(entityId));
    console.log("Coord");
    console.logInt(coord.x);
    console.logInt(coord.y);
    console.logInt(coord.z);
    address chipAddress = Chip.getChipAddress(entityId);
    console.log("Chip address:");
    console.logAddress(chipAddress);
    uint256 energyLevel = Energy.getEnergy(entityId);
    console.log("Energy level:");
    console.logUint(energyLevel);
    VoxelCoord memory shardCoord = coord.toForceFieldShardCoord();
    EntityId forceFieldEntityId = ForceField.get(shardCoord.x, shardCoord.y, shardCoord.z);
    if (!forceFieldEntityId.exists()) {
      console.log("No force field found at position");
    } else {
      PositionData memory positionData = Position.get(forceFieldEntityId);
      console.log("Force field position:");
      console.logBytes32(EntityId.unwrap(forceFieldEntityId));
      console.logInt(positionData.x);
      console.logInt(positionData.y);
      console.logInt(positionData.z);
    }

    vm.stopBroadcast();
  }
}
