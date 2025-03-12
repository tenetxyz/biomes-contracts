// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console } from "forge-std/console.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { GasReporter } from "@latticexyz/gas-report/src/GasReporter.sol";

import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";

import { ObjectAmount, getOreObjectTypes } from "../src/ObjectTypeLib.sol";

import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Mass } from "../src/codegen/tables/Mass.sol";
import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { ReversePlayer } from "../src/codegen/tables/ReversePlayer.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { BaseEntity } from "../src/codegen/tables/BaseEntity.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { PlayerActivity } from "../src/codegen/tables/PlayerActivity.sol";
import { ForceField } from "../src/codegen/tables/ForceField.sol";
import { Vec3 } from "../src/Vec3.sol";
import { InventoryEntity } from "../src/codegen/tables/InventoryEntity.sol";
import { ReverseInventoryEntity } from "../src/codegen/tables/ReverseInventoryEntity.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../src/codegen/tables/InventoryObjects.sol";

import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";

import { Position, ReversePosition, PlayerPosition, ReversePlayerPosition, LocalEnergyPool } from "../src/utils/Vec3Storage.sol";

import { encodeChunk } from "./utils/encodeChunk.sol";
import { EntityId } from "../src/EntityId.sol";
import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";
import { CHUNK_SIZE, PLAYER_MINE_ENERGY_COST, PLAYER_ENERGY_DRAIN_RATE } from "../src/Constants.sol";
import { energyToMass } from "../src/utils/EnergyUtils.sol";
import { TestForceFieldUtils } from "./utils/TestUtils.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";

abstract contract BiomesAssertions is MudTest, GasReporter {
  struct EnergyDataSnapshot {
    uint128 playerEnergy;
    uint128 localPoolEnergy;
    uint128 forceFieldEnergy;
  }

  function inventoryObjectsHasObjectType(
    EntityId ownerEntityId,
    ObjectTypeId objectTypeId
  ) internal view returns (bool) {
    uint16[] memory inventoryObjectTypes = InventoryObjects.get(ownerEntityId);
    for (uint256 i = 0; i < inventoryObjectTypes.length; i++) {
      if (inventoryObjectTypes[i] == ObjectTypeId.unwrap(objectTypeId)) {
        return true;
      }
    }
    return false;
  }

  function reverseInventoryEntityHasEntity(
    EntityId ownerEntityId,
    EntityId inventoryEntityId
  ) internal view returns (bool) {
    bytes32[] memory inventoryEntityIds = ReverseInventoryEntity.get(ownerEntityId);
    for (uint256 i = 0; i < inventoryEntityIds.length; i++) {
      if (inventoryEntityIds[i] == EntityId.unwrap(inventoryEntityId)) {
        return true;
      }
    }
    return false;
  }

  function inventoryGetOreAmounts(EntityId owner) internal view returns (ObjectAmount[] memory) {
    ObjectTypeId[] memory ores = getOreObjectTypes();

    uint256 numOres = 0;
    for (uint256 i = 0; i < ores.length; i++) {
      if (InventoryCount.get(owner, ores[i]) > 0) numOres++;
    }

    ObjectAmount[] memory oreAmounts = new ObjectAmount[](numOres);
    for (uint256 i = 0; i < ores.length; i++) {
      uint16 count = InventoryCount.get(owner, ores[i]);
      if (count > 0) {
        oreAmounts[numOres - 1] = ObjectAmount(ores[i], count);
        numOres--;
      }
    }

    return oreAmounts;
  }

  function assertInventoryHasObject(EntityId entityId, ObjectTypeId objectTypeId, uint16 amount) internal view {
    assertEq(InventoryCount.get(entityId, objectTypeId), amount, "Inventory count is not correct");
    if (amount > 0) {
      assertTrue(inventoryObjectsHasObjectType(entityId, objectTypeId), "Inventory objects does not have object type");
    } else {
      assertFalse(inventoryObjectsHasObjectType(entityId, objectTypeId), "Inventory objects has object type");
    }
  }

  function assertInventoryHasTool(EntityId entityId, EntityId toolEntityId, uint16 amount) internal view {
    assertInventoryHasObject(entityId, ObjectType.get(toolEntityId), amount);
    if (amount > 0) {
      assertEq(InventoryEntity.get(toolEntityId), entityId, "Inventory entity is not owned by entity");
      assertTrue(
        reverseInventoryEntityHasEntity(entityId, toolEntityId),
        "Inventory entity is not in reverse inventory entity"
      );
    } else {
      assertFalse(InventoryEntity.get(toolEntityId) == entityId, "Inventory entity is not owned by entity");
      assertFalse(
        reverseInventoryEntityHasEntity(entityId, toolEntityId),
        "Inventory entity is in reverse inventory entity"
      );
    }
  }

  function getEnergyDataSnapshot(
    EntityId playerEntityId,
    Vec3 snapshotCoord
  ) internal returns (EnergyDataSnapshot memory) {
    EnergyDataSnapshot memory snapshot;
    snapshot.playerEnergy = Energy.getEnergy(playerEntityId);
    Vec3 shardCoord = snapshotCoord.toLocalEnergyPoolShardCoord();
    snapshot.localPoolEnergy = LocalEnergyPool.get(shardCoord);
    (EntityId forceFieldEntityId, ) = TestForceFieldUtils.getForceField(snapshotCoord);
    snapshot.forceFieldEnergy = forceFieldEntityId.exists() ? Energy.getEnergy(forceFieldEntityId) : 0;
    return snapshot;
  }

  function assertEnergyFlowedFromPlayerToLocalPool(
    EnergyDataSnapshot memory beforeEnergyDataSnapshot,
    EnergyDataSnapshot memory afterEnergyDataSnapshot
  ) internal pure returns (uint128 playerEnergyLost) {
    playerEnergyLost = beforeEnergyDataSnapshot.playerEnergy - afterEnergyDataSnapshot.playerEnergy;
    assertGt(playerEnergyLost, 0, "Player energy did not decrease");
    uint128 localPoolEnergyGained = afterEnergyDataSnapshot.localPoolEnergy - beforeEnergyDataSnapshot.localPoolEnergy;
    assertEq(localPoolEnergyGained, playerEnergyLost, "Local pool energy did not gain energy");
  }

  function assertEq(Vec3 a, Vec3 b, string memory err) internal pure {
    assertTrue(a == b, err);
  }

  function assertEq(Vec3 a, Vec3 b) internal pure {
    assertTrue(a == b, "");
  }

  function assertEq(EntityId a, EntityId b, string memory err) internal pure {
    assertTrue(a == b, err);
  }

  function assertEq(EntityId a, EntityId b) internal pure {
    assertTrue(a == b, "");
  }

  function assertEq(ObjectTypeId a, ObjectTypeId b, string memory err) internal pure {
    assertTrue(a == b, err);
  }

  function assertEq(ObjectTypeId a, ObjectTypeId b) internal pure {
    assertTrue(a == b, "");
  }
}
