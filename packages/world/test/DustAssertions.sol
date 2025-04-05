// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { GasReporter } from "@latticexyz/gas-report/src/GasReporter.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { console } from "forge-std/console.sol";

import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";

import { ObjectAmount, getOreObjectTypes } from "../src/ObjectTypeLib.sol";

import { Vec3 } from "../src/Vec3.sol";
import { BaseEntity } from "../src/codegen/tables/BaseEntity.sol";
import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";

import { Inventory } from "../src/codegen/tables/Inventory.sol";

import { InventorySlot } from "../src/codegen/tables/InventorySlot.sol";
import { InventoryTypeSlots } from "../src/codegen/tables/InventoryTypeSlots.sol";
import { Mass } from "../src/codegen/tables/Mass.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";

import { Player } from "../src/codegen/tables/Player.sol";
import { ReversePlayer } from "../src/codegen/tables/ReversePlayer.sol";

import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";

import {
  LocalEnergyPool,
  MovablePosition,
  Position,
  ReverseMovablePosition,
  ReversePosition
} from "../src/utils/Vec3Storage.sol";

import { EntityId } from "../src/EntityId.sol";

import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";
import { ProgramId } from "../src/ProgramId.sol";
import { TestForceFieldUtils } from "./utils/TestUtils.sol";
import { encodeChunk } from "./utils/encodeChunk.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";

abstract contract DustAssertions is MudTest, GasReporter {
  struct EnergyDataSnapshot {
    uint128 playerEnergy;
    uint128 localPoolEnergy;
    uint128 forceFieldEnergy;
  }

  function getObjectAmount(EntityId owner, ObjectTypeId objectType) internal view returns (uint16) {
    uint16[] memory slots = InventoryTypeSlots.get(owner, objectType);
    if (slots.length == 0) {
      return 0;
    }

    uint16 total;
    for (uint256 i; i < slots.length; i++) {
      total += InventorySlot.getAmount(owner, slots[i]);
    }

    return total;
  }

  function inventoryHasObjectType(EntityId ownerEntityId, ObjectTypeId objectTypeId) internal view returns (bool) {
    return InventoryTypeSlots.length(ownerEntityId, objectTypeId) > 0;
  }

  function inventoryGetOreAmounts(EntityId owner) internal view returns (ObjectAmount[] memory) {
    ObjectTypeId[] memory ores = getOreObjectTypes();

    uint256 numOres = 0;
    for (uint256 i = 0; i < ores.length; i++) {
      if (InventoryTypeSlots.length(owner, ores[i]) > 0) numOres++;
    }

    ObjectAmount[] memory oreAmounts = new ObjectAmount[](numOres);
    for (uint256 i = 0; i < ores.length; i++) {
      uint256 count = getObjectAmount(owner, ores[i]);
      if (count > 0) {
        oreAmounts[numOres - 1] = ObjectAmount(ores[i], uint16(count));
        numOres--;
      }
    }

    return oreAmounts;
  }

  function assertInventoryHasObject(EntityId owner, ObjectTypeId objectTypeId, uint16 amount) internal view {
    uint256 actualAmount = getObjectAmount(owner, objectTypeId);
    assertEq(actualAmount, amount, "Inventory object amount is not correct");
  }

  function assertInventoryHasTool(EntityId owner, EntityId toolEntityId, uint16 amount) internal view {
    uint16[] memory slots = InventoryTypeSlots.get(owner, ObjectType.get(toolEntityId));
    bool found;
    if (slots.length > 0) {
      for (uint256 i; i < slots.length; i++) {
        if (toolEntityId == InventorySlot.getEntityId(owner, slots[i])) {
          found = true;
          break;
        }
      }
    }

    assertEq(found ? 1 : 0, amount, "Inventory entity doesn't match");
  }

  function getEnergyDataSnapshot(EntityId playerEntityId, Vec3 snapshotCoord)
    internal
    returns (EnergyDataSnapshot memory)
  {
    EnergyDataSnapshot memory snapshot;
    snapshot.playerEnergy = Energy.getEnergy(playerEntityId);
    Vec3 shardCoord = snapshotCoord.toLocalEnergyPoolShardCoord();
    snapshot.localPoolEnergy = LocalEnergyPool.get(shardCoord);
    (EntityId forceFieldEntityId,) = TestForceFieldUtils.getForceField(snapshotCoord);
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
    assertTrue(a == b);
  }

  function assertEq(EntityId a, EntityId b, string memory err) internal pure {
    assertTrue(a == b, err);
  }

  function assertEq(EntityId a, EntityId b) internal pure {
    assertTrue(a == b);
  }

  function assertEq(ProgramId a, ProgramId b, string memory err) internal pure {
    assertTrue(a == b, err);
  }

  function assertEq(ProgramId a, ProgramId b) internal pure {
    assertTrue(a == b);
  }

  function assertEq(ObjectTypeId a, ObjectTypeId b, string memory err) internal pure {
    assertTrue(a == b, err);
  }

  function assertEq(ObjectTypeId a, ObjectTypeId b) internal pure {
    assertTrue(a == b);
  }

  function assertNeq(ObjectTypeId a, ObjectTypeId b, string memory err) internal pure {
    assertTrue(a != b, err);
  }

  function assertNeq(ObjectTypeId a, ObjectTypeId b) internal pure {
    assertTrue(a != b);
  }
}
