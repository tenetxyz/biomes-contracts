// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { LibPRNG } from "solady/utils/LibPRNG.sol";

import { MinedOreCount } from "../codegen/tables/MinedOreCount.sol";
import { TotalMinedOreCount } from "../codegen/tables/TotalMinedOreCount.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { BedPlayer } from "../codegen/tables/BedPlayer.sol";
import { Orientation } from "../codegen/tables/Orientation.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Mass } from "../codegen/tables/Mass.sol";
import { SeedGrowth } from "../codegen/tables/SeedGrowth.sol";
import { DisplayContent, DisplayContentData } from "../codegen/tables/DisplayContent.sol";
import { DisplayContentType } from "../codegen/common.sol";

import { Position } from "../utils/Vec3Storage.sol";
import { MinedOrePosition } from "../utils/Vec3Storage.sol";
import { OreCommitment } from "../utils/Vec3Storage.sol";

import { getUniqueEntity } from "../Utils.sol";
import { addToInventory, useEquipped } from "../utils/InventoryUtils.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";
import { updateMachineEnergy, energyToMass, transferEnergyToPool, addEnergyToLocalPool, updateSleepingPlayerEnergy } from "../utils/EnergyUtils.sol";
import { getForceField, destroyForceField } from "../utils/ForceFieldUtils.sol";
import { notify, MineNotifData } from "../utils/NotifUtils.sol";
import { getOrCreateEntityAt, getObjectTypeIdAt, createEntityAt, getEntityAt, getPlayer } from "../utils/EntityUtils.sol";
import { callProgramOrRevert } from "../utils/callProgram.sol";

import { MoveLib } from "./libraries/MoveLib.sol";

import { IForceFieldFragmentProgram } from "../prototypes/IForceFieldProgram.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { ObjectTypeLib, ObjectAmount } from "../ObjectTypeLib.sol";
import { EntityId } from "../EntityId.sol";
import { CHUNK_COMMIT_EXPIRY_BLOCKS, MAX_COAL, MAX_SILVER, MAX_GOLD, MAX_DIAMOND, MAX_NEPTUNIUM } from "../Constants.sol";
import { PLAYER_MINE_ENERGY_COST, PLAYER_ENERGY_DRAIN_RATE } from "../Constants.sol";
import { Vec3, vec3 } from "../Vec3.sol";

contract MineSystem is System {
  using ObjectTypeLib for ObjectTypeId;

  function _removeBlock(EntityId entityId, Vec3 coord) internal {
    ObjectType._set(entityId, ObjectTypes.Air);

    Vec3 aboveCoord = coord + vec3(0, 1, 0);
    EntityId aboveEntityId = getPlayer(aboveCoord);
    // Note: currently it is not possible for the above player to not be the base entity,
    // but if we add other types of movable entities we should check that it is a base entity
    if (aboveEntityId.exists()) {
      MoveLib.runGravity(aboveEntityId, aboveCoord);
    }
  }

  function _handleDrop(EntityId playerEntityId, ObjectTypeId mineObjectTypeId) internal {
    ObjectAmount[] memory amounts = mineObjectTypeId.getMineDrop();

    for (uint256 i = 0; i < amounts.length; i++) {
      addToInventory(playerEntityId, ObjectTypes.Player, amounts[i].objectTypeId, amounts[i].amount);
    }
  }

  function _requireSeedNotFullyGrown(EntityId entityId) internal view {
    require(SeedGrowth._getFullyGrownAt(entityId) > block.timestamp, "Cannot mine fully grown seed");
  }

  function mine(Vec3 coord, bytes calldata extraData) public payable returns (EntityId) {
    (EntityId playerEntityId, Vec3 playerCoord, ) = PlayerUtils.requireValidPlayer(_msgSender());
    PlayerUtils.requireInPlayerInfluence(playerCoord, coord);

    (EntityId entityId, ObjectTypeId mineObjectTypeId) = getOrCreateEntityAt(coord);
    require(mineObjectTypeId.isMineable(), "Object is not mineable");

    transferEnergyToPool(playerEntityId, playerCoord, PLAYER_MINE_ENERGY_COST);

    EntityId baseEntityId = entityId.baseEntityId();
    Vec3 baseCoord = Position._get(baseEntityId);

    // Program needs to be detached first
    require(baseEntityId.getProgram().unwrap() == 0, "Cannot mine a programped block");
    if (mineObjectTypeId.isMachine()) {
      (EnergyData memory machineData, ) = updateMachineEnergy(baseEntityId);
      require(machineData.energy == 0, "Cannot mine a machine that has energy");
    } else if (mineObjectTypeId.isSeed()) {
      _requireSeedNotFullyGrown(baseEntityId);
    } else if (mineObjectTypeId == ObjectTypes.AnyOre) {
      mineObjectTypeId = MineLib._mineRandomOre(baseEntityId, coord);
    }

    // First coord will be the base coord, the rest is relative schema coords
    Vec3[] memory coords = mineObjectTypeId.getRelativeCoords(baseCoord, Orientation._get(baseEntityId));

    uint128 finalMass;
    {
      finalMass = MineLib._processMassReduction(playerEntityId, baseEntityId);
      if (finalMass == 0) {
        if (mineObjectTypeId == ObjectTypes.Bed) {
          // If mining a bed with a sleeping player, kill the player
          MineLib._mineBed(baseEntityId, baseCoord);
        }

        if (DisplayContent._getContentType(baseEntityId) != DisplayContentType.None) {
          DisplayContent._deleteRecord(baseEntityId);
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
            _handleDrop(playerEntityId, aboveTypeId);
          }
        }

        _removeBlock(baseEntityId, baseCoord);
        _handleDrop(playerEntityId, mineObjectTypeId);

        // If object being mined is a seed, return its energy to local pool
        if (mineObjectTypeId.isSeed()) {
          addEnergyToLocalPool(coord, ObjectTypeMetadata._getEnergy(mineObjectTypeId));
        }

        // Only iterate through relative schema coords
        for (uint256 i = 1; i < coords.length; i++) {
          Vec3 relativeCoord = coords[i];
          (EntityId relativeEntityId, ) = getEntityAt(relativeCoord);
          BaseEntity._deleteRecord(relativeEntityId);

          _removeBlock(relativeEntityId, relativeCoord);
        }
      } else {
        Mass._setMass(baseEntityId, finalMass);
      }
    }

    notify(
      playerEntityId,
      MineNotifData({ mineEntityId: baseEntityId, mineCoord: coord, mineObjectTypeId: mineObjectTypeId })
    );

    MineLib._requireMinesAllowed(playerEntityId, mineObjectTypeId, coords, extraData);

    if (mineObjectTypeId == ObjectTypes.ForceField && finalMass == 0) {
      destroyForceField(baseEntityId);
    }

    return baseEntityId;
  }

  function mineUntilDestroyed(Vec3 coord, bytes calldata extraData) public payable {
    uint128 massLeft = 0;
    do {
      // TODO: factor out the mass reduction logic so it's cheaper to call
      EntityId entityId = mine(coord, extraData);
      massLeft = Mass._getMass(entityId);
    } while (massLeft > 0);
  }
}

library MineLib {
  using LibPRNG for LibPRNG.PRNG;

  function _mineRandomOre(EntityId entityId, Vec3 coord) public returns (ObjectTypeId) {
    Vec3 chunkCoord = coord.toChunkCoord();
    uint256 commitment = OreCommitment._get(chunkCoord);
    // We can't get blockhash of current block
    require(block.number > commitment, "Not within commitment blocks");
    require(block.number <= commitment + CHUNK_COMMIT_EXPIRY_BLOCKS, "Ore commitment expired");

    // Set total mined ore and add position
    // We do this here to avoid stack too deep issues
    uint256 totalMinedOre = TotalMinedOreCount._get();
    MinedOrePosition._set(totalMinedOre, coord);
    TotalMinedOreCount._set(totalMinedOre + 1);

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

    ObjectTypeId ore = ores[oreIndex];
    MinedOreCount._set(ore, max[oreIndex] - remaining[oreIndex] + 1);
    ObjectType._set(entityId, ore);
    Mass._setMass(entityId, ObjectTypeMetadata._getMass(ore));

    return ore;
  }

  function _processMassReduction(EntityId playerEntityId, EntityId minedEntityId) public returns (uint128) {
    // TODO: balancing, what should the proper mass and energy cost be?
    uint128 massLeft = Mass._getMass(minedEntityId);
    uint128 baseMassReduction = energyToMass(PLAYER_MINE_ENERGY_COST);
    if (massLeft <= baseMassReduction) {
      return 0;
    }
    massLeft -= baseMassReduction;
    (uint128 toolMassReduction, ) = useEquipped(playerEntityId, massLeft);
    return massLeft <= toolMassReduction ? 0 : massLeft - toolMassReduction;
  }

  function _mineBed(EntityId bedEntityId, Vec3 bedCoord) public {
    EntityId sleepingPlayerId = BedPlayer._getPlayerEntityId(bedEntityId);
    if (sleepingPlayerId.exists()) {
      (EntityId forceFieldEntityId, ) = getForceField(bedCoord);
      (, uint128 depletedTime) = updateMachineEnergy(forceFieldEntityId);
      EnergyData memory playerData = updateSleepingPlayerEnergy(sleepingPlayerId, bedEntityId, depletedTime, bedCoord);
      PlayerUtils.removePlayerFromBed(sleepingPlayerId, bedEntityId, forceFieldEntityId);

      // This kills the player
      transferEnergyToPool(sleepingPlayerId, bedCoord, playerData.energy);
    }
  }

  function _requireMinesAllowed(
    EntityId playerEntityId,
    ObjectTypeId objectTypeId,
    Vec3[] memory coords,
    bytes calldata extraData
  ) public {
    for (uint256 i = 0; i < coords.length; i++) {
      Vec3 coord = coords[i];
      (EntityId forceFieldEntityId, EntityId fragmentEntityId) = getForceField(coord);
      if (forceFieldEntityId.exists()) {
        (EnergyData memory machineData, ) = updateMachineEnergy(forceFieldEntityId);
        if (machineData.energy > 0) {
          bytes memory onMineCall = abi.encodeCall(
            IForceFieldFragmentProgram.onMine,
            (forceFieldEntityId, playerEntityId, objectTypeId, coord, extraData)
          );

          // We know fragment is active because its forcefield exists, so we can use its program
          ResourceId fragmentProgram = fragmentEntityId.getProgram();
          if (fragmentProgram.unwrap() != 0) {
            callProgramOrRevert(fragmentProgram, onMineCall);
          } else {
            callProgramOrRevert(forceFieldEntityId.getProgram(), onMineCall);
          }
        }
      }
    }
  }
}
