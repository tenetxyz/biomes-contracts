// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { VoxelCoord } from "../VoxelCoord.sol";
import { Mass } from "../codegen/tables/Mass.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { PlayerPosition } from "../codegen/tables/PlayerPosition.sol";
import { ReversePlayerPosition } from "../codegen/tables/ReversePlayerPosition.sol";
import { InventoryObjects } from "../codegen/tables/InventoryObjects.sol";
import { Orientation } from "../codegen/tables/Orientation.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { ForceFieldMetadata } from "../codegen/tables/ForceFieldMetadata.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { ActionType, FacingDirection } from "../codegen/common.sol";

import { ObjectType, AirObjectID, PlayerObjectID } from "../ObjectType.sol";
import { inWorldBorder, getUniqueEntity } from "../Utils.sol";
import { removeFromInventoryCount } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";

import { PLAYER_BUILD_ENERGY_COST } from "../Constants.sol";
import { transferEnergyToPool } from "../utils/EnergyUtils.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";
import { ForceFieldLib } from "./libraries/ForceFieldLib.sol";
import { notify, BuildNotifData, MoveNotifData } from "../utils/NotifUtils.sol";
import { MoveLib } from "./libraries/MoveLib.sol";
import { EntityId } from "../EntityId.sol";

library BuildLib {
  function _addBlock(ObjectType buildObjectType, VoxelCoord memory coord) public returns (EntityId) {
    require(inWorldBorder(coord), "Cannot build outside the world border");
    (EntityId terrainEntityId, ObjectType terrainObjectType) = coord.getOrCreateEntity();
    require(terrainObjectType == AirObjectID, "Cannot build on a non-air block");
    require(
      InventoryObjects._lengthObjectTypes(terrainEntityId) == 0,
      "Cannot build where there are dropped objects"
    );
    if (!ObjectTypeMetadata._getCanPassThrough(buildObjectType)) {
      require(!coord.getPlayer().exists(), "Cannot build on a player");
    }

    ObjectType._set(terrainEntityId, buildObjectType);

    return terrainEntityId;
  }
}

contract BuildSystem is System {
  function buildWithExtraData(
    ObjectType buildObjectType,
    VoxelCoord memory baseCoord,
    FacingDirection facingDirection,
    bytes memory extraData
  ) public payable returns (EntityId) {
    require(buildObjectType.isBlock(), "Cannot build non-block object");
    (EntityId playerEntityId, VoxelCoord memory playerCoord, ) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, baseCoord);

    EntityId baseEntityId = BuildLib._addBlock(buildObjectType, baseCoord);
    Orientation._set(baseEntityId, facingDirection);
    uint32 mass = ObjectTypeMetadata._getMass(buildObjectType);
    Mass._setMass(baseEntityId, mass);

    VoxelCoord[] memory coords = baseCoord.getRelativeCoords(buildObjectType, facingDirection);
    // Only iterate through relative schema coords
    for (uint256 i = 1; i < coords.length; i++) {
      VoxelCoord memory relativeCoord = coords[i];
      EntityId relativeEntityId = BuildLib._addBlock(buildObjectType, relativeCoord);
      BaseEntity._set(relativeEntityId, baseEntityId);
    }

    VoxelCoord memory forceFieldShardCoord = baseCoord.toForceFieldShardCoord();
    ForceFieldMetadata._setTotalMassInside(
      forceFieldShardCoord.x,
      forceFieldShardCoord.y,
      forceFieldShardCoord.z,
      ForceFieldMetadata._getTotalMassInside(forceFieldShardCoord.x, forceFieldShardCoord.y, forceFieldShardCoord.z) +
        mass
    );

    transferEnergyToPool(playerEntityId, playerCoord, PLAYER_BUILD_ENERGY_COST);

    removeFromInventoryCount(playerEntityId, buildObjectType, 1);

    notify(
      playerEntityId,
      BuildNotifData({ buildEntityId: baseEntityId, buildCoord: baseCoord, buildObjectType: buildObjectType })
    );

    // Note: we call this after the build state has been updated, to prevent re-entrancy attacks
    ForceFieldLib.requireBuildsAllowed(playerEntityId, baseEntityId, buildObjectType, coords, extraData);

    return baseEntityId;
  }

  function jumpBuildWithExtraData(
    ObjectType buildObjectType,
    FacingDirection facingDirection,
    bytes memory extraData
  ) public payable {
    (EntityId playerEntityId, VoxelCoord memory playerCoord, ) = requireValidPlayer(_msgSender());

    VoxelCoord[] memory moveCoords = new VoxelCoord[](1);
    moveCoords[0] = VoxelCoord(playerCoord.x, playerCoord.y + 1, playerCoord.z);
    MoveLib.movePlayer(playerEntityId, playerCoord, moveCoords);
    notify(playerEntityId, MoveNotifData({ moveCoords: moveCoords }));

    require(!ObjectTypeMetadata._getCanPassThrough(buildObjectType), "Cannot jump build on a pass-through block");

    buildWithExtraData(buildObjectType, playerCoord, facingDirection, extraData);
  }

  function jumpBuildWithFacingDirection(
    ObjectType buildObjectType,
    FacingDirection facingDirection
  ) public payable {
    jumpBuildWithExtraData(buildObjectType, facingDirection, new bytes(0));
  }

  function jumpBuild(ObjectType buildObjectType) public payable {
    jumpBuildWithExtraData(buildObjectType, FacingDirection.PositiveZ, new bytes(0));
  }

  function buildWithFacingDirection(
    ObjectType buildObjectType,
    VoxelCoord memory baseCoord,
    FacingDirection facingDirection
  ) public payable returns (EntityId) {
    return buildWithExtraData(buildObjectType, baseCoord, facingDirection, new bytes(0));
  }

  function build(ObjectType buildObjectType, VoxelCoord memory baseCoord) public payable returns (EntityId) {
    return buildWithExtraData(buildObjectType, baseCoord, FacingDirection.PositiveZ, new bytes(0));
  }
}
