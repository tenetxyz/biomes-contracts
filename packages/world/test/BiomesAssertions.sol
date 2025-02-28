// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console } from "forge-std/console.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { GasReporter } from "@latticexyz/gas-report/src/GasReporter.sol";

import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";

import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Mass } from "../src/codegen/tables/Mass.sol";
import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { ReversePlayer } from "../src/codegen/tables/ReversePlayer.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { Position } from "../src/codegen/tables/Position.sol";
import { ForceField } from "../src/codegen/tables/ForceField.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { PlayerPosition } from "../src/codegen/tables/PlayerPosition.sol";
import { ReversePlayerPosition } from "../src/codegen/tables/ReversePlayerPosition.sol";
import { BaseEntity } from "../src/codegen/tables/BaseEntity.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { PlayerActivity } from "../src/codegen/tables/PlayerActivity.sol";
import { LocalEnergyPool } from "../src/codegen/tables/LocalEnergyPool.sol";
import { VoxelCoord, VoxelCoordLib } from "../src/VoxelCoord.sol";
import { InventoryEntity } from "../src/codegen/tables/InventoryEntity.sol";
import { ReverseInventoryEntity } from "../src/codegen/tables/ReverseInventoryEntity.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { EntityId } from "../src/EntityId.sol";
import { ChunkCoord } from "../src/Types.sol";
import { encodeChunk } from "./utils/encodeChunk.sol";
import { ObjectTypeId, PlayerObjectID, AirObjectID, DirtObjectID, SpawnTileObjectID, GrassObjectID, WaterObjectID, ForceFieldObjectID } from "../src/ObjectTypeIds.sol";
import { CHUNK_SIZE, PLAYER_MINE_ENERGY_COST, MAX_PLAYER_ENERGY, PLAYER_ENERGY_DRAIN_RATE } from "../src/Constants.sol";
import { energyToMass } from "../src/utils/EnergyUtils.sol";
import { getObjectTypeSchema } from "../src/utils/ObjectTypeUtils.sol";
import { TestUtils } from "./utils/TestUtils.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";

abstract contract BiomesAssertions is MudTest, GasReporter {
  struct EnergyDataSnapshot {
    uint128 playerEnergy;
    uint128 localPoolEnergy;
    uint128 forceFieldEnergy;
  }

  using VoxelCoordLib for *;

  function assertInventoryHasObject(EntityId entityId, ObjectTypeId objectTypeId, uint16 amount) internal view {
    assertEq(InventoryCount.get(entityId, objectTypeId), amount, "Inventory count is not correct");
    if (amount > 0) {
      assertTrue(
        TestUtils.inventoryObjectsHasObjectType(entityId, objectTypeId),
        "Inventory objects does not have object type"
      );
    } else {
      assertFalse(TestUtils.inventoryObjectsHasObjectType(entityId, objectTypeId), "Inventory objects has object type");
    }
  }

  function assertInventoryHasTool(EntityId entityId, EntityId toolEntityId, uint16 amount) internal view {
    assertInventoryHasObject(entityId, ObjectType.get(toolEntityId), amount);
    if (amount > 0) {
      assertTrue(InventoryEntity.get(toolEntityId) == entityId, "Inventory entity is not owned by entity");
      assertTrue(
        TestUtils.reverseInventoryEntityHasEntity(entityId, toolEntityId),
        "Inventory entity is not in reverse inventory entity"
      );
    } else {
      assertFalse(InventoryEntity.get(toolEntityId) == entityId, "Inventory entity is not owned by entity");
      assertFalse(
        TestUtils.reverseInventoryEntityHasEntity(entityId, toolEntityId),
        "Inventory entity is in reverse inventory entity"
      );
    }
  }

  function getEnergyDataSnapshot(
    EntityId playerEntityId,
    VoxelCoord memory snapshotCoord
  ) internal view returns (EnergyDataSnapshot memory) {
    EnergyDataSnapshot memory snapshot;
    snapshot.playerEnergy = Energy.getEnergy(playerEntityId);
    VoxelCoord memory shardCoord = snapshotCoord.toLocalEnergyPoolShardCoord();
    snapshot.localPoolEnergy = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);
    VoxelCoord memory forceFieldShardCoord = snapshotCoord.toForceFieldShardCoord();
    EntityId forceFieldEntityId = ForceField.get(
      forceFieldShardCoord.x,
      forceFieldShardCoord.y,
      forceFieldShardCoord.z
    );
    snapshot.forceFieldEnergy = forceFieldEntityId.exists() ? Energy.getEnergy(forceFieldEntityId) : 0;
    return snapshot;
  }

  function assertEnergyFlowedFromPlayerToLocalPool(
    EnergyDataSnapshot memory beforeEnergyDataSnapshot,
    EnergyDataSnapshot memory afterEnergyDataSnapshot
  ) internal pure {
    uint128 playerEnergyLost = beforeEnergyDataSnapshot.playerEnergy - afterEnergyDataSnapshot.playerEnergy;
    assertTrue(playerEnergyLost > 0, "Player energy did not decrease");
    uint128 localPoolEnergyGained = afterEnergyDataSnapshot.localPoolEnergy - beforeEnergyDataSnapshot.localPoolEnergy;
    assertEq(localPoolEnergyGained, playerEnergyLost, "Local pool energy did not gain energy");
  }
}
