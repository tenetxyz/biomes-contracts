// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { LibPRNG } from "solady/utils/LibPRNG.sol";

import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { BedPlayer } from "../codegen/tables/BedPlayer.sol";

import { DisplayURI } from "../codegen/tables/DisplayURI.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Mass } from "../codegen/tables/Mass.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Orientation } from "../codegen/tables/Orientation.sol";
import { ResourceCount } from "../codegen/tables/ResourceCount.sol";
import { SeedGrowth } from "../codegen/tables/SeedGrowth.sol";
import { TotalBurnedResourceCount } from "../codegen/tables/TotalBurnedResourceCount.sol";

import { Position } from "../utils/Vec3Storage.sol";
import { ResourcePosition } from "../utils/Vec3Storage.sol";
import { ChunkCommitment } from "../utils/Vec3Storage.sol";

import { getUniqueEntity } from "../Utils.sol";

import {
  addEnergyToLocalPool,
  decreasePlayerEnergy,
  transferEnergyToPool,
  updateMachineEnergy,
  updatePlayerEnergy,
  updateSleepingPlayerEnergy
} from "../utils/EnergyUtils.sol";

import {
  createEntityAt,
  getEntityAt,
  getMovableEntityAt,
  getObjectTypeIdAt,
  getOrCreateEntityAt
} from "../utils/EntityUtils.sol";
import { destroyForceField, getForceField } from "../utils/ForceFieldUtils.sol";
import { addToInventory, useEquipped } from "../utils/InventoryUtils.sol";
import { DeathNotification, MineNotification, notify } from "../utils/NotifUtils.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";

import { MoveLib } from "./libraries/MoveLib.sol";
import { RandomResourceLib } from "./libraries/RandomResourceLib.sol";

import { MINE_ENERGY_COST, SAFE_PROGRAM_GAS } from "../Constants.sol";
import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectAmount, ObjectTypeLib } from "../ObjectTypeLib.sol";

import { ObjectTypes } from "../ObjectTypes.sol";
import { ResourceLib } from "../ResourceLib.sol";
import { ResourceCategory } from "../codegen/common.sol";

import { ProgramId } from "../ProgramId.sol";
import { IDetachProgramHook, IMineHook } from "../ProgramInterfaces.sol";
import { Vec3, vec3 } from "../Vec3.sol";

contract MineSystem is System {
  using ObjectTypeLib for ObjectTypeId;

  function _removeBlock(EntityId entityId, Vec3 coord) internal {
    ObjectType._set(entityId, ObjectTypes.Air);

    Vec3 aboveCoord = coord + vec3(0, 1, 0);
    EntityId above = getMovableEntityAt(aboveCoord);
    // Note: currently it is not possible for the above player to not be the base entity,
    // but if we add other types of movable entities we should check that it is a base entity
    if (above.exists()) {
      MoveLib.runGravity(above, aboveCoord);
    }
  }

  function _handleDrop(EntityId caller, ObjectTypeId mineObjectTypeId, Vec3 coord) internal {
    // Get a randomness seed based on the caller, block number, and coordinates
    bytes32 seed = keccak256(abi.encodePacked(caller, block.number, coord));

    // Get drops with all metadata for resource tracking
    ResourceLib.ResourceDropResult memory result = ResourceLib.getResourceDrops(mineObjectTypeId, seed);

    // Add resources to inventory
    for (uint256 i = 0; i < result.amounts.length; i++) {
      addToInventory(caller, ObjectType._get(caller), result.amounts[i].objectTypeId, result.amounts[i].amount);

      // Track resource if needed
      if (result.requiresResourceTracking) {
        ResourceCount._set(
          result.amounts[i].objectTypeId, ResourceCount._get(result.amounts[i].objectTypeId) + result.amounts[i].amount
        );
      }
    }

    // Handle resource pool return (for seeds that weren't harvested)
    if (result.returnToPool) {
      TotalBurnedResourceCount._set(result.category, TotalBurnedResourceCount._get(result.category) + 1);
    }
  }

  function _requireSeedNotFullyGrown(EntityId entityId) internal view {
    require(SeedGrowth._getFullyGrownAt(entityId) > block.timestamp, "Cannot mine fully grown seed");
  }

  function getRandomResourceType(Vec3 coord, ResourceCategory category) external view returns (ObjectTypeId) {
    (ObjectTypeId resourceType,) = RandomResourceLib._getRandomResourceType(coord, category);
    return resourceType;
  }

  function mine(EntityId caller, Vec3 coord, bytes calldata extraData) public payable returns (EntityId) {
    caller.activate();
    caller.requireConnected(coord);

    (EntityId entityId, ObjectTypeId mineObjectTypeId) = getOrCreateEntityAt(coord);
    require(mineObjectTypeId.isMineable(), "Object is not mineable");

    entityId = entityId.baseEntityId();
    Vec3 baseCoord = Position._get(entityId);

    if (mineObjectTypeId.isMachine()) {
      (EnergyData memory machineData,) = updateMachineEnergy(entityId);
      require(machineData.energy == 0, "Cannot mine a machine that has energy");
    } else if (mineObjectTypeId.isSeed()) {
      _requireSeedNotFullyGrown(entityId);
    } else if (mineObjectTypeId == ObjectTypes.AnyOre) {
      // Handle random resource generation
      ResourceCategory category = ResourceCategory.Mining; // Default to mining for AnyOre
      mineObjectTypeId = RandomResourceLib._mineRandomResource(entityId, coord, category);
    }

    // First coord will be the base coord, the rest is relative schema coords
    Vec3[] memory coords = mineObjectTypeId.getRelativeCoords(baseCoord, Orientation._get(entityId));

    uint128 finalMass;
    {
      finalMass = MassReductionLib._processMassReduction(caller, entityId);
      if (finalMass == 0) {
        if (mineObjectTypeId == ObjectTypes.Bed) {
          // If mining a bed with a sleeping player, kill the player
          MineLib._mineBed(entityId, baseCoord);
        }

        if (bytes(DisplayURI._get(entityId)).length > 0) {
          DisplayURI._deleteRecord(entityId);
        }

        Mass._deleteRecord(entityId);

        {
          // Remove seeds placed on top of this block
          Vec3 aboveCoord = baseCoord + vec3(0, 1, 0);
          (EntityId above, ObjectTypeId aboveTypeId) = getEntityAt(aboveCoord);
          if (aboveTypeId.isSeed()) {
            _requireSeedNotFullyGrown(entityId);
            if (!above.exists()) {
              above = createEntityAt(aboveCoord, aboveTypeId);
            }
            _removeBlock(above, aboveCoord);
            _handleDrop(caller, aboveTypeId, aboveCoord);
          }
        }

        _removeBlock(entityId, baseCoord);
        _handleDrop(caller, mineObjectTypeId, baseCoord);

        // If object being mined is a seed, return its energy to local pool
        if (mineObjectTypeId.isSeed()) {
          addEnergyToLocalPool(coord, ObjectTypeMetadata._getEnergy(mineObjectTypeId));
        }

        // Only iterate through relative schema coords
        for (uint256 i = 1; i < coords.length; i++) {
          Vec3 relativeCoord = coords[i];
          (EntityId relative,) = getEntityAt(relativeCoord);
          BaseEntity._deleteRecord(relative);

          _removeBlock(relative, relativeCoord);
        }
      } else {
        Mass._setMass(entityId, finalMass);
      }
    }

    MineLib._requireMinesAllowed(caller, mineObjectTypeId, coord, extraData);

    if (finalMass == 0) {
      // Detach program if it exists
      ProgramId program = entityId.getProgram();
      if (program.exists()) {
        bytes memory onDetachProgram = abi.encodeCall(IDetachProgramHook.onDetachProgram, (caller, entityId, extraData));
        program.call({ gas: SAFE_PROGRAM_GAS, hook: onDetachProgram });
      }

      if (mineObjectTypeId == ObjectTypes.ForceField) {
        destroyForceField(entityId);
      }
    }

    notify(caller, MineNotification({ mineEntityId: entityId, mineCoord: coord, mineObjectTypeId: mineObjectTypeId }));

    return entityId;
  }

  function mineUntilDestroyed(EntityId caller, Vec3 coord, bytes calldata extraData) public payable {
    uint128 massLeft = 0;
    do {
      // TODO: factor out the mass reduction logic so it's cheaper to call
      EntityId entityId = mine(caller, coord, extraData);
      massLeft = Mass._getMass(entityId);
    } while (massLeft > 0);
  }
}

library MineLib {
  function _mineBed(EntityId bed, Vec3 bedCoord) public {
    EntityId sleepingPlayerId = BedPlayer._getPlayerEntityId(bed);
    if (sleepingPlayerId.exists()) {
      (EntityId forceField,) = getForceField(bedCoord);
      (, uint128 depletedTime) = updateMachineEnergy(forceField);
      EnergyData memory playerData = updateSleepingPlayerEnergy(sleepingPlayerId, bed, depletedTime, bedCoord);
      PlayerUtils.removePlayerFromBed(sleepingPlayerId, bed, forceField);

      // Kill the player
      // The player is not on the grid so no need to call killPlayer
      Energy._setEnergy(sleepingPlayerId, 0);
      addEnergyToLocalPool(bedCoord, playerData.energy);
      notify(sleepingPlayerId, DeathNotification({ deathCoord: bedCoord }));
    }
  }

  function _requireMinesAllowed(EntityId caller, ObjectTypeId objectTypeId, Vec3 coord, bytes calldata extraData)
    public
  {
    (EntityId forceField, EntityId fragment) = getForceField(coord);

    if (!forceField.exists()) {
      return;
    }
    (EnergyData memory machineData,) = updateMachineEnergy(forceField);
    if (machineData.energy == 0) {
      return;
    }

    // We know fragment is active because its forcefield exists, so we can use its program
    ProgramId program = fragment.getProgram();
    if (!program.exists()) {
      program = forceField.getProgram();
      if (!program.exists()) {
        return;
      }
    }

    bytes memory onMine = abi.encodeCall(IMineHook.onMine, (caller, forceField, objectTypeId, coord, extraData));

    program.callOrRevert(onMine);
  }
}

library MassReductionLib {
  function _processMassReduction(EntityId caller, EntityId mined) public returns (uint128) {
    uint128 massLeft = Mass._getMass(mined);
    if (massLeft == 0) {
      return massLeft;
    }

    (uint128 toolMassReduction,) = useEquipped(caller, massLeft);

    // if tool mass reduction is not enough, consume energy from player up to mine energy cost
    if (toolMassReduction < massLeft) {
      uint128 remaining = massLeft - toolMassReduction;
      uint128 energyReduction = MINE_ENERGY_COST <= remaining ? MINE_ENERGY_COST : remaining;
      transferEnergyToPool(caller, energyReduction);
      massLeft -= energyReduction;
    }

    return massLeft - toolMassReduction;
  }
}
