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
import { ActionType, Direction } from "../codegen/common.sol";

import { ForceFieldMetadata, PlayerPosition, ReversePlayerPosition } from "../utils/Vec3Storage.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { inWorldBorder, getUniqueEntity } from "../Utils.sol";
import { removeFromInventoryCount } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { getOrCreateEntityAt } from "../utils/EntityUtils.sol";

import { PLAYER_BUILD_ENERGY_COST } from "../Constants.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";
import { ForceFieldLib } from "./libraries/ForceFieldLib.sol";
import { MoveLib } from "./libraries/MoveLib.sol";
import { transferEnergyToPool } from "../utils/EnergyUtils.sol";
import { getPlayer } from "../utils/EntityUtils.sol";
import { notify, BuildNotifData, MoveNotifData } from "../utils/NotifUtils.sol";
import { EntityId } from "../EntityId.sol";
import { Vec3, vec3 } from "../Vec3.sol";

library BuildLib {
  function _addBlock(ObjectTypeId buildObjectTypeId, Vec3 coord) public returns (EntityId) {
    require(inWorldBorder(coord), "Cannot build outside the world border");
    (EntityId terrainEntityId, ObjectTypeId terrainObjectTypeId) = getOrCreateEntityAt(coord);
    require(terrainObjectTypeId == ObjectTypes.Air, "Cannot build on a non-air block");
    require(
      InventoryObjects._lengthObjectTypeIds(terrainEntityId) == 0,
      "Cannot build where there are dropped objects"
    );
    if (!ObjectTypeMetadata._getCanPassThrough(buildObjectTypeId)) {
      require(!getPlayer(coord).exists(), "Cannot build on a player");
    }

    ObjectType._set(terrainEntityId, buildObjectTypeId);

    return terrainEntityId;
  }
}

contract BuildSystem is System {
  function buildWithExtraData(
    ObjectTypeId buildObjectTypeId,
    Vec3 baseCoord,
    Direction direction,
    bytes memory extraData
  ) public payable returns (EntityId) {
    require(buildObjectTypeId.isBlock(), "Cannot build non-block object");
    (EntityId playerEntityId, Vec3 playerCoord, ) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, baseCoord);

    EntityId baseEntityId = BuildLib._addBlock(buildObjectTypeId, baseCoord);
    Orientation._set(baseEntityId, direction);
    uint32 mass = ObjectTypeMetadata._getMass(buildObjectTypeId);
    Mass._setMass(baseEntityId, mass);

    Vec3[] memory coords = buildObjectTypeId.getRelativeCoords(baseCoord, direction);
    // Only iterate through relative schema coords
    for (uint256 i = 1; i < coords.length; i++) {
      Vec3 relativeCoord = coords[i];
      EntityId relativeEntityId = BuildLib._addBlock(buildObjectTypeId, relativeCoord);
      BaseEntity._set(relativeEntityId, baseEntityId);
    }

    Vec3 forceFieldShardCoord = baseCoord.toForceFieldShardCoord();
    ForceFieldMetadata._setTotalMassInside(
      forceFieldShardCoord,
      ForceFieldMetadata._getTotalMassInside(forceFieldShardCoord) + mass
    );

    transferEnergyToPool(playerEntityId, playerCoord, PLAYER_BUILD_ENERGY_COST);

    removeFromInventoryCount(playerEntityId, buildObjectTypeId, 1);

    notify(
      playerEntityId,
      BuildNotifData({ buildEntityId: baseEntityId, buildCoord: baseCoord, buildObjectTypeId: buildObjectTypeId })
    );

    // Note: we call this after the build state has been updated, to prevent re-entrancy attacks
    ForceFieldLib.requireBuildsAllowed(playerEntityId, baseEntityId, buildObjectTypeId, coords, extraData);

    return baseEntityId;
  }

  function jumpBuildWithExtraData(
    ObjectTypeId buildObjectTypeId,
    Direction direction,
    bytes memory extraData
  ) public payable {
    (EntityId playerEntityId, Vec3 playerCoord, ) = requireValidPlayer(_msgSender());

    Vec3[] memory moveCoords = new Vec3[](1);
    moveCoords[0] = playerCoord + vec3(0, 1, 0);
    MoveLib.movePlayer(playerEntityId, playerCoord, moveCoords);
    notify(playerEntityId, MoveNotifData({ moveCoords: moveCoords }));

    require(!ObjectTypeMetadata._getCanPassThrough(buildObjectTypeId), "Cannot jump build on a pass-through block");

    buildWithExtraData(buildObjectTypeId, playerCoord, direction, extraData);
  }

  function jumpBuildWithDirection(ObjectTypeId buildObjectTypeId, Direction direction) public payable {
    jumpBuildWithExtraData(buildObjectTypeId, direction, new bytes(0));
  }

  function jumpBuild(ObjectTypeId buildObjectTypeId) public payable {
    jumpBuildWithExtraData(buildObjectTypeId, Direction.PositiveZ, new bytes(0));
  }

  function buildWithDirection(
    ObjectTypeId buildObjectTypeId,
    Vec3 baseCoord,
    Direction direction
  ) public payable returns (EntityId) {
    return buildWithExtraData(buildObjectTypeId, baseCoord, direction, new bytes(0));
  }

  function build(ObjectTypeId buildObjectTypeId, Vec3 baseCoord) public payable returns (EntityId) {
    return buildWithExtraData(buildObjectTypeId, baseCoord, Direction.PositiveZ, new bytes(0));
  }
}
