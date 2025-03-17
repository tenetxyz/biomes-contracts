// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { SeedGrowth } from "../codegen/tables/SeedGrowth.sol";

import { useEquipped } from "../utils/InventoryUtils.sol";
import { getOrCreateEntityAt } from "../utils/EntityUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { massToEnergy, transferEnergyToPool } from "../utils/EnergyUtils.sol";

import { EntityId } from "../EntityId.sol";
import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { Vec3, vec3 } from "../Vec3.sol";
import { PLAYER_TILL_ENERGY_COST } from "../Constants.sol";

contract FarmingSystem is System {
  using ObjectTypeLib for ObjectTypeId;

  function till(Vec3 coord) external {
    (EntityId playerEntityId, Vec3 playerCoord, ) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, coord);

    (EntityId farmlandEntityId, ObjectTypeId objectTypeId) = getOrCreateEntityAt(coord);
    require(objectTypeId == ObjectTypes.Dirt || objectTypeId == ObjectTypes.Grass, "Not dirt or grass");
    (uint128 massUsed, ObjectTypeId toolObjectTypeId) = useEquipped(playerEntityId, type(uint128).max);
    require(toolObjectTypeId.isHoe(), "Must equip a hoe");

    uint128 energyCost = PLAYER_TILL_ENERGY_COST + massToEnergy(massUsed);
    transferEnergyToPool(playerEntityId, playerCoord, energyCost);

    ObjectType._set(farmlandEntityId, ObjectTypes.Farmland);
  }

  function growSeed(Vec3 coord) external {
    requireValidPlayer(_msgSender());

    (EntityId seedEntityId, ObjectTypeId objectTypeId) = getOrCreateEntityAt(coord);
    require(objectTypeId.isSeed(), "Not a seed");

    require(SeedGrowth._getFullyGrownAt(seedEntityId) <= block.timestamp, "Seed cannot be grown yet");

    // Turn wet farmland to dirt if mining a seed or crop
    (EntityId belowEntityId, ObjectTypeId belowTypeId) = getOrCreateEntityAt(coord - vec3(0, 1, 0));
    // Sanity check
    if (belowTypeId == ObjectTypes.WetFarmland) {
      ObjectType._set(belowEntityId, ObjectTypes.Farmland);
    }

    ObjectType._set(seedEntityId, objectTypeId.getCrop());
  }
}
