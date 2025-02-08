// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { console } from "forge-std/console.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { InventoryTool } from "../src/codegen/tables/InventoryTool.sol";
import { ReverseInventoryTool } from "../src/codegen/tables/ReverseInventoryTool.sol";
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
import { ShardField } from "../src/codegen/tables/ShardField.sol";
import { Energy } from "../src/codegen/tables/Energy.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { coordToShardCoord } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { positionDataToVoxelCoord } from "../src/Utils.sol";
import { FORCE_FIELD_SHARD_DIM } from "../src/Constants.sol";

contract ReadScript is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    IWorld world = IWorld(worldAddress);

    bytes32 playerEntityId = Player.get(0xE0ae70caBb529336e25FA7a1f036b77ad0089d2a);
    require(playerEntityId != bytes32(0), "Player entity not found");
    console.log("Player");
    console.logBytes32(playerEntityId);
    console.logBool(PlayerStatus.getIsLoggedOff(playerEntityId));

    // VoxelCoord memory coord = VoxelCoord(150, 1, -160);
    bytes32 entityId = 0x00000000000000000000000000000000000000000000000000000000002a4960;
    console.log("Entity at position:");
    console.logBytes32(entityId);
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
    VoxelCoord memory shardCoord = coordToShardCoord(coord, FORCE_FIELD_SHARD_DIM);
    bytes32 forceFieldEntityId = ShardField.get(shardCoord.x, shardCoord.y, shardCoord.z);
    if (forceFieldEntityId == bytes32(0)) {
      console.log("No force field found at position");
    } else {
      PositionData memory positionData = Position.get(forceFieldEntityId);
      console.log("Force field position:");
      console.logBytes32(forceFieldEntityId);
      console.logInt(positionData.x);
      console.logInt(positionData.y);
      console.logInt(positionData.z);
    }

    vm.stopBroadcast();
  }
}
