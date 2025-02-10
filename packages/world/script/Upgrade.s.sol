// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";

import { InventoryTool } from "../src/codegen/tables/InventoryTool.sol";
import { ReverseInventoryTool } from "../src/codegen/tables/ReverseInventoryTool.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../src/codegen/tables/InventoryObjects.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { ReversePlayer } from "../src/codegen/tables/ReversePlayer.sol";
import { Position } from "../src/codegen/tables/Position.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { Chip } from "../src/codegen/tables/Chip.sol";
import { Recipes } from "../src/codegen/tables/Recipes.sol";

import { BedrockObjectID, ChestObjectID, AnyReinforcedLumberObjectID, SandObjectID, CoalOreObjectID, ChipBatteryObjectID, GlassObjectID, StoneObjectID, QuartziteObjectID, LimestoneObjectID, EmberstoneObjectID, MoonstoneObjectID, SunstoneObjectID, GoldOreObjectID, GoldBarObjectID, SilverOreObjectID, SilverBarObjectID, DiamondOreObjectID, DiamondObjectID, NeptuniumOreObjectID, NeptuniumBarObjectID } from "../src/ObjectTypeIds.sol";

contract Upgrade is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    bytes32[] memory entityIds = new bytes32[](4);
    entityIds[0] = 0x000000000000000000000000000000000000000000000000000000000000577f;
    entityIds[1] = 0x000000000000000000000000000000000000000000000000000000000000578e;
    entityIds[2] = 0x0000000000000000000000000000000000000000000000000000000000008b46;
    entityIds[3] = 0x000000000000000000000000000000000000000000000000000000000000ae8d;

    for (uint i = 0; i < entityIds.length; i++) {
      bytes32 entityId = entityIds[i];
      // if (
      //   entityId == 0x00000000000000000000000000000000000000000000000000000000000309d4 ||
      //   entityId == 0x00000000000000000000000000000000000000000000000000000000002a4960
      // ) {
      //   continue;
      // }
      require(Chip.getChipAddress(entityId) == 0x4509365cf5eCd4a8dB0BE9259c6339F1e49882C2, "Chip address not set");
      Chip.setChipAddress(entityId, 0xCfEEc31cc4ac48830D1bc0c630B082Aeac3c4912);
    }

    // bytes32 recipeId1 = keccak256(abi.encodePacked(GoldOreObjectID, uint16(4), GoldBarObjectID, uint16(1)));
    // bytes32 recipeId2 = keccak256(abi.encodePacked(SilverOreObjectID, uint16(4), SilverBarObjectID, uint16(1)));
    // bytes32 recipeId3 = keccak256(abi.encodePacked(DiamondOreObjectID, uint16(4), DiamondObjectID, uint16(1)));
    // bytes32 recipeId4 = keccak256(abi.encodePacked(NeptuniumOreObjectID, uint16(4), NeptuniumBarObjectID, uint16(1)));
    // bytes32 recipeId5 = keccak256(
    //   abi.encodePacked(LimestoneObjectID, uint16(4), CoalOreObjectID, uint16(4), SunstoneObjectID, uint16(4))
    // );

    // console.log("recipe");
    // console.logUint(Recipes.getOutputObjectTypeId(recipeId1));
    // console.logUint(Recipes.getOutputObjectTypeId(recipeId2));
    // console.logUint(Recipes.getOutputObjectTypeId(recipeId3));
    // console.logUint(Recipes.getOutputObjectTypeId(recipeId4));
    // console.logUint(Recipes.getOutputObjectTypeId(recipeId5));

    // Recipes.deleteRecord(recipeId1);
    // Recipes.deleteRecord(recipeId2);
    // Recipes.deleteRecord(recipeId3);
    // Recipes.deleteRecord(recipeId4);
    // Recipes.deleteRecord(recipeId5);

    vm.stopBroadcast();
  }
}
