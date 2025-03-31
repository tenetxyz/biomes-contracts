// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Mass } from "../codegen/tables/Mass.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { InventoryObjects } from "../codegen/tables/InventoryObjects.sol";
import { Orientation } from "../codegen/tables/Orientation.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { SeedGrowth } from "../codegen/tables/SeedGrowth.sol";
import { ActionType, Direction } from "../codegen/common.sol";

import { MovablePosition, ReverseMovablePosition } from "../utils/Vec3Storage.sol";

import { getUniqueEntity } from "../Utils.sol";
import { removeFromInventory } from "../utils/InventoryUtils.sol";
import { getOrCreateEntityAt, getObjectTypeIdAt, getMovableEntityAt } from "../utils/EntityUtils.sol";
import { removeEnergyFromLocalPool, updateMachineEnergy, transferEnergyToPool } from "../utils/EnergyUtils.sol";
import { getForceField, setupForceField } from "../utils/ForceFieldUtils.sol";
import { notify, BuildNotifData, MoveNotifData } from "../utils/NotifUtils.sol";

import { TerrainLib } from "./libraries/TerrainLib.sol";
import { MoveLib } from "./libraries/MoveLib.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { EntityId } from "../EntityId.sol";
import { ProgramId } from "../ProgramId.sol";
import { IHooks } from "../IHooks.sol";
import { Vec3, vec3 } from "../Vec3.sol";
import { BUILD_ENERGY_COST } from "../Constants.sol";

using ObjectTypeLib for ObjectTypeId;

library BuildLib {
  function _addBlock(ObjectTypeId buildObjectTypeId, Vec3 coord) internal returns (EntityId) {
    (EntityId terrainEntityId, ObjectTypeId terrainObjectTypeId) = getOrCreateEntityAt(coord);
    require(terrainObjectTypeId == ObjectTypes.Air, "Cannot build on a non-air block");
    require(
      InventoryObjects._lengthObjectTypeIds(terrainEntityId) == 0,
      "Cannot build where there are dropped objects"
    );
    if (!ObjectTypeMetadata._getCanPassThrough(buildObjectTypeId)) {
      require(!getMovableEntityAt(coord).exists(), "Cannot build on a movable entity");
    }

    ObjectType._set(terrainEntityId, buildObjectTypeId);

    return terrainEntityId;
  }

  function _addBlocks(
    Vec3 baseCoord,
    ObjectTypeId buildObjectTypeId,
    Direction direction
  ) public returns (EntityId, Vec3[] memory) {
    Vec3[] memory coords = buildObjectTypeId.getRelativeCoords(baseCoord, direction);
    EntityId baseEntityId = _addBlock(buildObjectTypeId, baseCoord);
    Orientation._set(baseEntityId, direction);
    uint32 mass = ObjectTypeMetadata._getMass(buildObjectTypeId);
    Mass._setMass(baseEntityId, mass);
    // Only iterate through relative schema coords
    for (uint256 i = 1; i < coords.length; i++) {
      Vec3 relativeCoord = coords[i];
      EntityId relativeEntityId = _addBlock(buildObjectTypeId, relativeCoord);
      BaseEntity._set(relativeEntityId, baseEntityId);
    }
    return (baseEntityId, coords);
  }

  function _handleSeed(EntityId baseEntityId, ObjectTypeId buildObjectTypeId, Vec3 baseCoord) public {
    ObjectTypeId belowTypeId = getObjectTypeIdAt(baseCoord - vec3(0, 1, 0));
    if (buildObjectTypeId.isCropSeed()) {
      require(belowTypeId == ObjectTypes.WetFarmland, "Crop seeds need wet farmland");
    } else if (buildObjectTypeId.isTreeSeed()) {
      require(belowTypeId == ObjectTypes.Dirt || belowTypeId == ObjectTypes.Grass, "Tree seeds need dirt or grass");
    }

    removeEnergyFromLocalPool(baseCoord, ObjectTypeMetadata._getEnergy(buildObjectTypeId));

    SeedGrowth._setFullyGrownAt(baseEntityId, uint128(block.timestamp) + buildObjectTypeId.timeToGrow());
  }

  function _requireBuildsAllowed(
    EntityId callerEntityId,
    EntityId baseEntityId,
    ObjectTypeId objectTypeId,
    Vec3[] memory coords,
    bytes calldata extraData
  ) public {
    for (uint256 i = 0; i < coords.length; i++) {
      Vec3 coord = coords[i];
      (EntityId forceFieldEntityId, EntityId fragmentEntityId) = getForceField(coord);

      // If placing a forcefield, there should be no active forcefield at coord
      if (objectTypeId == ObjectTypes.ForceField) {
        require(!forceFieldEntityId.exists(), "Force field overlaps with another force field");
        setupForceField(baseEntityId, coord);
      }

      if (forceFieldEntityId.exists()) {
        (EnergyData memory machineData, ) = updateMachineEnergy(forceFieldEntityId);
        if (machineData.energy > 0) {
          // We know fragment is active because its forcefield exists, so we can use its program
          ProgramId program = fragmentEntityId.getProgram();
          if (program.exists()) {
            program = forceFieldEntityId.getProgram();
          }

          bytes memory onBuild = abi.encodeCall(
            IHooks.onBuild,
            (callerEntityId, forceFieldEntityId, objectTypeId, coord, extraData)
          );

          program.callOrRevert(onBuild);
        }
      }
    }
  }
}

contract BuildSystem is System {
  function buildWithDirection(
    EntityId callerEntityId,
    ObjectTypeId buildObjectTypeId,
    Vec3 baseCoord,
    Direction direction,
    bytes calldata extraData
  ) public payable returns (EntityId) {
    callerEntityId.activate();
    callerEntityId.requireConnected(baseCoord);
    require(buildObjectTypeId.isBlock(), "Cannot build non-block object");

    (EntityId baseEntityId, Vec3[] memory coords) = BuildLib._addBlocks(baseCoord, buildObjectTypeId, direction);

    if (buildObjectTypeId.isSeed()) {
      BuildLib._handleSeed(baseEntityId, buildObjectTypeId, baseCoord);
    }

    removeFromInventory(callerEntityId, buildObjectTypeId, 1);

    transferEnergyToPool(callerEntityId, BUILD_ENERGY_COST);

    notify(
      callerEntityId,
      BuildNotifData({ buildEntityId: baseEntityId, buildCoord: coords[0], buildObjectTypeId: buildObjectTypeId })
    );

    // Note: we call this after the build state has been updated, to prevent re-entrancy attacks
    BuildLib._requireBuildsAllowed(callerEntityId, baseEntityId, buildObjectTypeId, coords, extraData);

    return baseEntityId;
  }

  function build(
    EntityId callerEntityId,
    ObjectTypeId buildObjectTypeId,
    Vec3 baseCoord,
    bytes calldata extraData
  ) public payable returns (EntityId) {
    return buildWithDirection(callerEntityId, buildObjectTypeId, baseCoord, Direction.PositiveZ, extraData);
  }

  function jumpBuildWithDirection(
    EntityId callerEntityId,
    ObjectTypeId buildObjectTypeId,
    Direction direction,
    bytes calldata extraData
  ) public payable {
    callerEntityId.activate();

    Vec3 coord = MovablePosition._get(callerEntityId);

    Vec3[] memory moveCoords = new Vec3[](1);
    moveCoords[0] = coord + vec3(0, 1, 0);
    MoveLib.moveWithoutGravity(callerEntityId, coord, moveCoords);

    notify(callerEntityId, MoveNotifData({ moveCoords: moveCoords }));

    require(!ObjectTypeMetadata._getCanPassThrough(buildObjectTypeId), "Cannot jump build on a pass-through block");

    buildWithDirection(callerEntityId, buildObjectTypeId, coord, direction, extraData);
  }

  function jumpBuild(EntityId callerEntityId, ObjectTypeId buildObjectTypeId, bytes calldata extraData) public payable {
    jumpBuildWithDirection(callerEntityId, buildObjectTypeId, Direction.PositiveZ, extraData);
  }
}
