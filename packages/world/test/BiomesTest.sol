// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { GasReporter } from "@latticexyz/gas-report/src/GasReporter.sol";

import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";

import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { ReversePlayer } from "../src/codegen/tables/ReversePlayer.sol";
import { Position } from "../src/codegen/tables/Position.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { PlayerActivity } from "../src/codegen/tables/PlayerActivity.sol";
import { VoxelCoord } from "../src/VoxelCoord.sol";
import { EntityId } from "../src/EntityId.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";

abstract contract BiomesTest is MudTest, GasReporter {
  IWorld internal world;

  function setUp() public virtual override {
    super.setUp();

    world = IWorld(worldAddress);

    // Transfer root ownership to this test contract
    ResourceId rootNamespace = WorldResourceIdLib.encodeNamespace(bytes14(0));
    address owner = NamespaceOwner.get(rootNamespace);
    vm.prank(owner);
    world.transferOwnership(rootNamespace, address(this));
  }

  function randomEntityId() internal returns (EntityId) {
    return EntityId.wrap(bytes32(vm.randomUint()));
  }

  // Create a valid player that can perform actions
  function createTestPlayer(VoxelCoord memory coord) internal returns (EntityId, address) {
    address playerAddress = vm.randomAddress();
    EntityId playerEntityId = randomEntityId();
    Player.set(playerAddress, playerEntityId);
    ReversePlayer.set(playerEntityId, playerAddress);
    Position.set(playerEntityId, coord.x, coord.y, coord.z);
    ReversePosition.set(coord.x, coord.y, coord.z, playerEntityId);
    Energy.set(playerEntityId, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 10000 }));
    PlayerActivity.set(playerEntityId, uint128(block.timestamp));
    return (playerEntityId, playerAddress);
  }
}
