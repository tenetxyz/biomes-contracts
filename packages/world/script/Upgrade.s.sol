// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { Unstable_CallWithSignatureSystem } from "@latticexyz/world-modules/src/modules/callwithsignature/Unstable_CallWithSignatureSystem.sol";
import { DELEGATION_SYSTEM_ID } from "@latticexyz/world-modules/src/modules/callwithsignature/constants.sol";
import { Recipes } from "../src/codegen/tables/Recipes.sol";
import { ChestMetadata, ChestMetadataData } from "../src/codegen/tables/ChestMetadata.sol";
import { BedrockObjectID, ChestObjectID, AnyReinforcedLumberObjectID, SandObjectID, CoalOreObjectID, ChipBatteryObjectID, GlassObjectID, StoneObjectID, QuartziteObjectID, LimestoneObjectID, EmberstoneObjectID, MoonstoneObjectID, SunstoneObjectID, GoldOreObjectID, GoldBarObjectID, SilverOreObjectID, SilverBarObjectID, DiamondOreObjectID, DiamondObjectID, NeptuniumOreObjectID, NeptuniumBarObjectID } from "../src/ObjectTypeIds.sol";

import { IERC165 } from "@latticexyz/store/src/IERC165.sol";

interface IChestTransferHook is IERC165 {
  function onHookSet(bytes32 chestEntityId) external;

  function onHookRemoved(bytes32 chestEntityId) external;

  function allowTransfer(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    uint8 transferObjectTypeId,
    uint16 numToTransfer,
    bytes32 toolEntityId,
    bytes memory extraData
  ) external payable returns (bool);
}

contract Upgrade is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    // Unstable_CallWithSignatureSystem newUpgradedSystem = new Unstable_CallWithSignatureSystem();
    // IWorld(worldAddress).registerSystem(DELEGATION_SYSTEM_ID, newUpgradedSystem, true);

    // IWorld(worldAddress).initThermoblastObjectTypes();
    // IWorld(worldAddress).initThermoblastRecipes();

    bytes32 recipeId1 = keccak256(abi.encodePacked(GoldOreObjectID, uint8(4), GoldBarObjectID, uint8(1)));
    bytes32 recipeId2 = keccak256(abi.encodePacked(SilverOreObjectID, uint8(4), SilverBarObjectID, uint8(1)));
    bytes32 recipeId3 = keccak256(abi.encodePacked(DiamondOreObjectID, uint8(4), DiamondObjectID, uint8(1)));
    bytes32 recipeId4 = keccak256(abi.encodePacked(NeptuniumOreObjectID, uint8(4), NeptuniumBarObjectID, uint8(1)));
    // bytes32 recipeId5 = keccak256(
    //   abi.encodePacked(LimestoneObjectID, uint8(4), CoalOreObjectID, uint8(4), SunstoneObjectID, uint8(4))
    // );

    console.log("recipe");
    console.logUint(Recipes.getOutputObjectTypeId(recipeId1));
    console.logUint(Recipes.getOutputObjectTypeId(recipeId2));
    console.logUint(Recipes.getOutputObjectTypeId(recipeId3));
    console.logUint(Recipes.getOutputObjectTypeId(recipeId4));
    // console.logUint(Recipes.getOutputObjectTypeId(recipeId5));

    // Recipes.deleteRecord(recipeId1);
    // Recipes.deleteRecord(recipeId2);
    // Recipes.deleteRecord(recipeId3);
    // Recipes.deleteRecord(recipeId4);
    // Recipes.deleteRecord(recipeId5);

    // bytes32[] memory entityIds = new bytes32[](2);
    // entityIds[0] = 0x00000000000000000000000000000000000000000000000000000000000005fe;
    // entityIds[1] = 0x0000000000000000000000000000000000000000000000000000000000000603;

    // for (uint i = 0; i < entityIds.length; i++) {
    //   bytes32 chestEntityId = entityIds[i];
    //   ChestMetadataData memory chestMetadata = ChestMetadata.get(chestEntityId);
    //   if (chestMetadata.owner == address(0)) {
    //     continue;
    //   }
    //   console.log("FOUND CHEST");
    //   console.logBytes32(chestEntityId);
    //   if (chestMetadata.onTransferHook != address(0)) {
    //     console.log("REMOVING HOOK");
    //     IChestTransferHook(chestMetadata.onTransferHook).onHookRemoved(chestEntityId);
    //     ChestMetadata.setOnTransferHook(chestEntityId, address(0));
    //   }
    //   if (chestMetadata.strength > 0) {
    //     console.log("SETTING STRENGTH TO 0");
    //     ChestMetadata.setStrength(chestEntityId, 0);
    //   }
    // }

    vm.stopBroadcast();
  }
}
