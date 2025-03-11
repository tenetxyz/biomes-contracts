// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";

import { useEquipped } from "../utils/InventoryUtils.sol";
import { getOrCreateEntityAt } from "../utils/EntityUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { massToEnergy, transferEnergyToPool } from "../utils/EnergyUtils.sol";

import { EntityId } from "../EntityId.sol";
import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { Vec3 } from "../Vec3.sol";
import { PLAYER_TILL_ENERGY_COST } from "../Constants.sol";

contract FarmingSystem is System {
  using ObjectTypeLib for ObjectTypeId;

  function till(Vec3 coord) external {
    (EntityId playerEntityId, Vec3 playerCoord, ) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, coord);

    (EntityId farmlandEntityId, ObjectTypeId objectTypeId) = getOrCreateEntityAt(coord);
    require(objectTypeId == ObjectTypes.Dirt || objectTypeId == ObjectTypes.Grass, "Not dirt or grass");
    (uint128 massUsed, ObjectTypeId toolObjectTypeId) = useEquipped(playerEntityId);
    require(toolObjectTypeId.isHoe(), "Must equip a hoe");

    uint128 energyCost = PLAYER_TILL_ENERGY_COST + massToEnergy(massUsed);
    transferEnergyToPool(playerEntityId, playerCoord, energyCost);

    ObjectType._set(farmlandEntityId, ObjectTypes.Farmland);
  }
}
