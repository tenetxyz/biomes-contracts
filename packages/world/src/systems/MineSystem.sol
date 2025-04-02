// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { LibPRNG } from "solady/utils/LibPRNG.sol";

import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { BedPlayer } from "../codegen/tables/BedPlayer.sol";

import { DisplayURI } from "../codegen/tables/DisplayURI.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Mass } from "../codegen/tables/Mass.sol";
import { MinedOreCount } from "../codegen/tables/MinedOreCount.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Orientation } from "../codegen/tables/Orientation.sol";
import { SeedGrowth } from "../codegen/tables/SeedGrowth.sol";
import { TotalMinedOreCount } from "../codegen/tables/TotalMinedOreCount.sol";

import { Position } from "../utils/Vec3Storage.sol";
import { MinedOrePosition } from "../utils/Vec3Storage.sol";
import { OreCommitment } from "../utils/Vec3Storage.sol";

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
import { DeathNotifData, MineNotifData, notify } from "../utils/NotifUtils.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";

import { MoveLib } from "./libraries/MoveLib.sol";

import {
  CHUNK_COMMIT_EXPIRY_BLOCKS,
  MAX_COAL,
  MAX_DIAMOND,
  MAX_GOLD,
  MAX_NEPTUNIUM,
  MAX_SILVER,
  SAFE_PROGRAM_GAS
} from "../Constants.sol";
import { MINE_ENERGY_COST } from "../Constants.sol";
import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectAmount, ObjectTypeLib } from "../ObjectTypeLib.sol";
import { ObjectTypes } from "../ObjectTypes.sol";

import { ProgramId } from "../ProgramId.sol";
import { IDetachProgramHook, IMineHook } from "../ProgramInterfaces.sol";
import { Vec3, vec3 } from "../Vec3.sol";

contract MineSystem is System {
  using ObjectTypeLib for ObjectTypeId;

  function _removeBlock(EntityId entityId, Vec3 coord) internal {
    ObjectType._set(entityId, ObjectTypes.Air);

    Vec3 aboveCoord = coord + vec3(0, 1, 0);
    EntityId aboveEntityId = getMovableEntityAt(aboveCoord);
    // Note: currently it is not possible for the above player to not be the base entity,
    // but if we add other types of movable entities we should check that it is a base entity
    if (aboveEntityId.exists()) {
      MoveLib.runGravity(aboveEntityId, aboveCoord);
    }
  }

  function _handleDrop(EntityId callerEntityId, ObjectTypeId mineObjectTypeId) internal {
    ObjectAmount[] memory amounts = mineObjectTypeId.getMineDrop();

    for (uint256 i = 0; i < amounts.length; i++) {
      addToInventory(callerEntityId, ObjectType._get(callerEntityId), amounts[i].objectTypeId, amounts[i].amount);
    }
  }

  function _requireSeedNotFullyGrown(EntityId entityId) internal view {
    require(SeedGrowth._getFullyGrownAt(entityId) > block.timestamp, "Cannot mine fully grown seed");
  }

  function getRandomOreType(Vec3 coord) external view returns (ObjectTypeId) {
    (ObjectTypeId ore,) = RandomOreLib._getRandomOreType(coord);
    return ore;
  }

  function mine(EntityId callerEntityId, Vec3 coord, bytes calldata extraData) public payable returns (EntityId) {
    callerEntityId.activate();
    callerEntityId.requireConnected(coord);

    (EntityId entityId, ObjectTypeId mineObjectTypeId) = getOrCreateEntityAt(coord);
    require(mineObjectTypeId.isMineable(), "Object is not mineable");

    EntityId baseEntityId = entityId.baseEntityId();
    Vec3 baseCoord = Position._get(baseEntityId);

    if (mineObjectTypeId.isMachine()) {
      (EnergyData memory machineData,) = updateMachineEnergy(baseEntityId);
      require(machineData.energy == 0, "Cannot mine a machine that has energy");
    } else if (mineObjectTypeId.isSeed()) {
      _requireSeedNotFullyGrown(baseEntityId);
    } else if (mineObjectTypeId == ObjectTypes.AnyOre) {
      mineObjectTypeId = RandomOreLib._mineRandomOre(baseEntityId, coord);
    }

    // First coord will be the base coord, the rest is relative schema coords
    Vec3[] memory coords = mineObjectTypeId.getRelativeCoords(baseCoord, Orientation._get(baseEntityId));

    uint128 finalMass;
    {
      finalMass = MassReductionLib._processMassReduction(callerEntityId, baseEntityId);
      if (finalMass == 0) {
        if (mineObjectTypeId == ObjectTypes.Bed) {
          // If mining a bed with a sleeping player, kill the player
          MineLib._mineBed(baseEntityId, baseCoord);
        }

        if (bytes(DisplayURI._get(baseEntityId)).length > 0) {
          DisplayURI._deleteRecord(baseEntityId);
        }

        Mass._deleteRecord(baseEntityId);

        {
          // Remove seeds placed on top of this block
          Vec3 aboveCoord = baseCoord + vec3(0, 1, 0);
          (EntityId aboveEntityId, ObjectTypeId aboveTypeId) = getEntityAt(aboveCoord);
          if (aboveTypeId.isSeed()) {
            _requireSeedNotFullyGrown(baseEntityId);
            if (!aboveEntityId.exists()) {
              aboveEntityId = createEntityAt(aboveCoord, aboveTypeId);
            }
            _removeBlock(aboveEntityId, aboveCoord);
            _handleDrop(callerEntityId, aboveTypeId);
          }
        }

        _removeBlock(baseEntityId, baseCoord);
        _handleDrop(callerEntityId, mineObjectTypeId);

        // If object being mined is a seed, return its energy to local pool
        if (mineObjectTypeId.isSeed()) {
          addEnergyToLocalPool(coord, ObjectTypeMetadata._getEnergy(mineObjectTypeId));
        }

        // Only iterate through relative schema coords
        for (uint256 i = 1; i < coords.length; i++) {
          Vec3 relativeCoord = coords[i];
          (EntityId relativeEntityId,) = getEntityAt(relativeCoord);
          BaseEntity._deleteRecord(relativeEntityId);

          _removeBlock(relativeEntityId, relativeCoord);
        }
      } else {
        Mass._setMass(baseEntityId, finalMass);
      }
    }

    MineLib._requireMinesAllowed(callerEntityId, mineObjectTypeId, coord, extraData);

    if (finalMass == 0) {
      // Detach program if it exists
      ProgramId program = baseEntityId.getProgram();
      if (program.exists()) {
        bytes memory onDetachProgram =
          abi.encodeCall(IDetachProgramHook.onDetachProgram, (callerEntityId, baseEntityId, extraData));
        program.call({ gas: SAFE_PROGRAM_GAS, hook: onDetachProgram });
      }

      if (mineObjectTypeId == ObjectTypes.ForceField) {
        destroyForceField(baseEntityId);
      }
    }

    notify(
      callerEntityId,
      MineNotifData({ mineEntityId: baseEntityId, mineCoord: coord, mineObjectTypeId: mineObjectTypeId })
    );

    return baseEntityId;
  }

  function mineUntilDestroyed(EntityId callerEntityId, Vec3 coord, bytes calldata extraData) public payable {
    uint128 massLeft = 0;
    do {
      // TODO: factor out the mass reduction logic so it's cheaper to call
      EntityId entityId = mine(callerEntityId, coord, extraData);
      massLeft = Mass._getMass(entityId);
    } while (massLeft > 0);
  }
}

library MineLib {
  function _mineBed(EntityId bedEntityId, Vec3 bedCoord) public {
    EntityId sleepingPlayerId = BedPlayer._getPlayerEntityId(bedEntityId);
    if (sleepingPlayerId.exists()) {
      (EntityId forceFieldEntityId,) = getForceField(bedCoord);
      (, uint128 depletedTime) = updateMachineEnergy(forceFieldEntityId);
      EnergyData memory playerData = updateSleepingPlayerEnergy(sleepingPlayerId, bedEntityId, depletedTime, bedCoord);
      PlayerUtils.removePlayerFromBed(sleepingPlayerId, bedEntityId, forceFieldEntityId);

      // Kill the player
      // The player is not on the grid so no need to call killPlayer
      Energy._setEnergy(sleepingPlayerId, 0);
      addEnergyToLocalPool(bedCoord, playerData.energy);
      notify(sleepingPlayerId, DeathNotifData({ deathCoord: bedCoord }));
    }
  }

  function _requireMinesAllowed(
    EntityId callerEntityId,
    ObjectTypeId objectTypeId,
    Vec3 coord,
    bytes calldata extraData
  ) public {
    (EntityId forceFieldEntityId, EntityId fragmentEntityId) = getForceField(coord);

    if (!forceFieldEntityId.exists()) {
      return;
    }
    (EnergyData memory machineData,) = updateMachineEnergy(forceFieldEntityId);
    if (machineData.energy == 0) {
      return;
    }

    // We know fragment is active because its forcefield exists, so we can use its program
    ProgramId program = fragmentEntityId.getProgram();
    if (!program.exists()) {
      program = forceFieldEntityId.getProgram();
      if (!program.exists()) {
        return;
      }
    }

    bytes memory onMine =
      abi.encodeCall(IMineHook.onMine, (callerEntityId, forceFieldEntityId, objectTypeId, coord, extraData));

    program.callOrRevert(onMine);
  }
}

library MassReductionLib {
  function _processMassReduction(EntityId callerEntityId, EntityId minedEntityId) public returns (uint128) {
    uint128 massLeft = Mass._getMass(minedEntityId);
    if (massLeft == 0) {
      return massLeft;
    }

    (uint128 toolMassReduction,) = useEquipped(callerEntityId, massLeft);

    // if tool mass reduction is not enough, consume energy from player up to mine energy cost
    if (toolMassReduction < massLeft) {
      uint128 remaining = massLeft - toolMassReduction;
      uint128 energyReduction = MINE_ENERGY_COST <= remaining ? MINE_ENERGY_COST : remaining;
      transferEnergyToPool(callerEntityId, energyReduction);
      massLeft -= energyReduction;
    }

    return massLeft - toolMassReduction;
  }
}

library RandomOreLib {
  using LibPRNG for LibPRNG.PRNG;

  function _getRandomOreType(Vec3 coord) public view returns (ObjectTypeId, uint256) {
    Vec3 chunkCoord = coord.toChunkCoord();
    uint256 commitment = OreCommitment._get(chunkCoord);
    // We can't get blockhash of current block
    require(block.number > commitment, "Not within commitment blocks");
    require(block.number <= commitment + CHUNK_COMMIT_EXPIRY_BLOCKS, "Ore commitment expired");

    // TODO: can optimize by not storing these in memory and returning the type depending on for loop index
    ObjectTypeId[5] memory ores = [
      ObjectTypes.CoalOre,
      ObjectTypes.SilverOre,
      ObjectTypes.GoldOre,
      ObjectTypes.DiamondOre,
      ObjectTypes.NeptuniumOre
    ];

    uint256[5] memory max = [MAX_COAL, MAX_SILVER, MAX_GOLD, MAX_DIAMOND, MAX_NEPTUNIUM];

    // For y > -50: More common ores (coal, silver)
    // For y <= -50: More rare ores (gold, diamond, neptunium)
    // uint256[5] memory depthMultiplier;
    // if (coord.y > -50) {
    //   depthMultiplier = [uint256(4), 3, 1, 1, 1];
    // } else {
    //   depthMultiplier = [uint256(1), 1, 3, 4, 4];
    // }

    // Calculate remaining amounts for each ore and total remaining
    uint256[5] memory remaining;
    uint256 totalRemaining = 0;
    for (uint256 i = 0; i < remaining.length; i++) {
      // remaining[i] = (max[i] - mined[i]) * depthMultiplier[i];
      remaining[i] = max[i] - MinedOreCount._get(ores[i]);
      totalRemaining += remaining[i];
    }

    require(totalRemaining > 0, "No ores available to mine");

    uint256 oreIndex = 0;
    {
      // Get pseudo random number between 0 and totalRemaining
      LibPRNG.PRNG memory prng;
      prng.seed(uint256(keccak256(abi.encodePacked(blockhash(commitment), coord))));
      uint256 scaledRand = prng.uniform(totalRemaining);

      uint256 acc;
      for (; oreIndex < remaining.length - 1; oreIndex++) {
        acc += remaining[oreIndex];
        if (scaledRand < acc) break;
      }
    }

    // Return ore type and mined ore count
    return (ores[oreIndex], max[oreIndex] - remaining[oreIndex] + 1);
  }

  function _mineRandomOre(EntityId entityId, Vec3 coord) public returns (ObjectTypeId) {
    (ObjectTypeId ore, uint256 minedOreCount) = _getRandomOreType(coord);
    // Set total mined ore and add position
    uint256 totalMinedOre = TotalMinedOreCount._get();
    MinedOrePosition._set(totalMinedOre, coord);
    TotalMinedOreCount._set(totalMinedOre + 1);

    MinedOreCount._set(ore, minedOreCount);
    ObjectType._set(entityId, ore);
    Mass._setMass(entityId, ObjectTypeMetadata._getMass(ore));

    return ore;
  }
}
