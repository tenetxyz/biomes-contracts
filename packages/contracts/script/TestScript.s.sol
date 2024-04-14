// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";
import { console } from "forge-std/console.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { Inventory } from "../src/codegen/tables/Inventory.sol";
import { ReverseInventory } from "../src/codegen/tables/ReverseInventory.sol";
import { ItemMetadata } from "../src/codegen/tables/ItemMetadata.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { Health } from "../src/codegen/tables/Health.sol";
import { Stamina } from "../src/codegen/tables/Stamina.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { ReversePlayer } from "../src/codegen/tables/ReversePlayer.sol";
import { PlayerMetadata } from "../src/codegen/tables/PlayerMetadata.sol";
import { Position } from "../src/codegen/tables/Position.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { GrassObjectID, OakLogObjectID, AirObjectID, OakLumberObjectID, PlayerObjectID, WoodenPickObjectID, ChestObjectID } from "@biomesaw/terrain/src/ObjectTypeIds.sol";
import { addToInventoryCount } from "../src/utils/InventoryUtils.sol";
import { testAddToInventoryCount } from "../test/utils/InventoryTestUtils.sol";

contract TestScript is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    IWorld world = IWorld(worldAddress);

    // world.spawnPlayer(VoxelCoord(148, -61, -24));
    // ObjectType.get(entityId)
    // bytes32 entityId = ReversePosition.get(148, -61, -24);
    // console.logBytes32(entityId);
    // console.logBytes32(ObjectType.get(entityId));
    // console.logAddress(ReversePlayer.get(entityId));
    // VoxelCoord memory spawnCoord = VoxelCoord(148, -61, -24);
    // bytes32 entityId = 0x0000000000000000000000000000000000000000000000000000000000000c36;
    // ObjectType.set(entityId, PlayerObjectID);
    // Health.deleteRecord(entityId);
    // Stamina.deleteRecord(entityId);

    // Health.set(entityId, block.timestamp, 1000);
    // Stamina.set(entityId, block.timestamp, 120000);

    // address newPlayer = 0x04Ed9A45747d67D1Ae7E253ed5713B1653C78E34;
    // Player.set(newPlayer, entityId);
    // ReversePlayer.set(entityId, newPlayer);
    // Player.deleteRecord(newPlayer);
    // ReversePlayer.deleteRecord(entityId);
    // PlayerMetadata.deleteRecord(entityId);

    // Player.set(newPlayer, entityId);
    // ReversePlayer.set(entityId, newPlayer);
    // Position.set(entityId, spawnCoord.x, spawnCoord.y, spawnCoord.z);
    // ReversePosition.set(spawnCoord.x, spawnCoord.y, spawnCoord.z, entityId);
    // world.teleport(VoxelCoord(149, -62, -37));

    bytes32 playerEntityId = Player.get(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    // uint8 inputObjectTypeId = GrassObjectID;
    // for (uint i = 0; i < 99; i++) {
    //   bytes32 newInventoryId = getUniqueEntity();
    //   ObjectType.set(newInventoryId, inputObjectTypeId);
    //   Inventory.set(newInventoryId, playerEntityId);
    //   ReverseInventory.push(playerEntityId, newInventoryId);
    // }
    // testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId, 99);

    // bytes32 newInventoryId1 = getUniqueEntity();
    // ObjectType.set(newInventoryId1, ChestObjectID);
    // Inventory.set(newInventoryId1, playerEntityId);
    // ReverseInventory.push(playerEntityId, newInventoryId1);
    // testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);

    uint8 inputObjectTypeId = OakLogObjectID;
    // bytes32 newInventoryId = getUniqueEntity();
    // ObjectType.set(newInventoryId, inputObjectTypeId);
    // Inventory.set(newInventoryId, playerEntityId);
    // ReverseInventory.push(playerEntityId, newInventoryId);
    // testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId, 1);
    // ItemMetadata.set(newInventoryId, 10);

    // world.equip(newInventoryId);
    // Equipped.set(playerEntityId, newInventoryId);

    // bytes32[] memory ingredientEntityIds = new bytes32[](1);
    // ingredientEntityIds[0] = newInventoryId;
    // world.drop(ingredientEntityIds, VoxelCoord(146, -63, -46));
    // console.logBytes32(newInventoryId);

    // bytes32 newInventoryId = 0x00000000000000000000000000000000000000000000000000000000000001e2;
    // world.equip(newInventoryId);
    // world.unequip();

    // uint8 outputObjectTypeId = OakLumberObjectID;
    // bytes32 recipeId = keccak256(abi.encodePacked(inputObjectTypeId, uint8(1), outputObjectTypeId, uint8(4)));

    // bytes32[] memory ingredientEntityIds = new bytes32[](1);
    // ingredientEntityIds[0] = newInventoryId;

    // world.craft(recipeId, ingredientEntityIds, bytes32(0));

    // bytes32[] memory ownedInventoryEntityIds = ReverseInventory.get(playerEntityId);
    // bytes32[] memory inventoryEntityIds = new bytes32[](1);
    // for (uint i = 0; i < ownedInventoryEntityIds.length; i++) {
    //   if (ObjectType.get(ownedInventoryEntityIds[i]) == OakLumberObjectID) {
    //     inventoryEntityIds[0] = ownedInventoryEntityIds[i];
    //     break;
    //   }
    // }
    bytes32 inventoryEntityId = world.mine(GrassObjectID, VoxelCoord(148, -63, -38));
    console.logBytes32(inventoryEntityId);
    // inventoryEntityIds[0] = 0x00000000000000000000000000000000000000000000000000000000000001d2;
    // world.drop(inventoryEntityIds, VoxelCoord(149, -63, -38));
    // world.teleport(VoxelCoord(148, -63, -50));
    // world.logoffPlayer();
    // inventoryEntityIds[0] = 0x00000000000000000000000000000000000000000000000000000000000001be;
    // world.drop(inventoryEntityIds, VoxelCoord(150, -62, -39));
    // world.teleport(VoxelCoord(150, -62, -39));
    // bytes32 dstEntityId = 0x00000000000000000000000000000000000000000000000000000000000001da;
    // world.transfer(playerEntityId, dstEntityId, inventoryEntityIds);

    // world.mine(ChestObjectID, VoxelCoord(149, -63, -57));
    // bytes32 inventoryEntityId = 0x00000000000000000000000000000000000000000000000000000000000001bc;
    // world.build(inventoryEntityId, VoxelCoord(150, -62, -38));
    // world.hit(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    // world.hit(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    // world.hit(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    // world.logoffPlayer();
    // world.loginPlayer(VoxelCoord(149, -63, -39));

    vm.stopBroadcast();
  }
}
