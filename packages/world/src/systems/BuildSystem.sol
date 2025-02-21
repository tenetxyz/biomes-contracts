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
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { ForceFieldMetadata } from "../codegen/tables/ForceFieldMetadata.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { ActionType } from "../codegen/common.sol";

import { ObjectTypeId, AirObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { inWorldBorder, getUniqueEntity } from "../Utils.sol";
import { removeFromInventoryCount } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";

import { PLAYER_BUILD_ENERGY_COST } from "../Constants.sol";
import { transferEnergyFromPlayerToPool } from "../utils/EnergyUtils.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";
import { ForceFieldLib } from "./libraries/ForceFieldLib.sol";
import { notify, BuildNotifData, MoveNotifData } from "../utils/NotifUtils.sol";
import { getObjectTypeSchema } from "../utils/ObjectTypeUtils.sol";
import { MoveLib } from "./libraries/MoveLib.sol";
import { EntityId } from "../EntityId.sol";

contract BuildSystem is System {
  function _addBlock(ObjectTypeId buildObjectTypeId, VoxelCoord memory coord) internal returns (EntityId) {
    require(inWorldBorder(coord), "Cannot build outside the world border");
    (EntityId terrainEntityId, ObjectTypeId terrainObjectTypeId, ) = coord.getOrCreateEntity();
    require(terrainObjectTypeId == AirObjectID, "Cannot build on a non-air block");
    require(
      InventoryObjects._lengthObjectTypeIds(terrainEntityId) == 0,
      "Cannot build where there are dropped objects"
    );
    if (!ObjectTypeMetadata._getCanPassThrough(buildObjectTypeId)) {
      require(!coord.getPlayer().exists(), "Cannot build on a player");
    }

    ObjectType._set(terrainEntityId, buildObjectTypeId);

    return terrainEntityId;
  }

  function buildWithExtraData(
    ObjectTypeId buildObjectTypeId,
    VoxelCoord memory baseCoord,
    bytes memory extraData
  ) public payable returns (EntityId) {
    require(buildObjectTypeId.isBlock(), "Cannot build non-block object");
    (EntityId playerEntityId, VoxelCoord memory playerCoord, EnergyData memory playerEnergyData) = requireValidPlayer(
      _msgSender()
    );
    requireInPlayerInfluence(playerCoord, baseCoord);

    EntityId baseEntityId = _addBlock(buildObjectTypeId, baseCoord);
    uint32 mass = ObjectTypeMetadata._getMass(buildObjectTypeId);
    Mass._setMass(baseEntityId, mass);

    VoxelCoord[] memory coords = baseCoord.getRelativeCoords(buildObjectTypeId);
    // Only iterate through relative schema coords
    for (uint256 i = 1; i < coords.length; i++) {
      VoxelCoord memory relativeCoord = coords[i];
      EntityId relativeEntityId = _addBlock(buildObjectTypeId, relativeCoord);
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

    transferEnergyFromPlayerToPool(playerEntityId, playerCoord, playerEnergyData, PLAYER_BUILD_ENERGY_COST);

    removeFromInventoryCount(playerEntityId, buildObjectTypeId, 1);

    notify(
      playerEntityId,
      BuildNotifData({ buildEntityId: baseEntityId, buildCoord: baseCoord, buildObjectTypeId: buildObjectTypeId })
    );

    // Note: we call this after the build state has been updated, to prevent re-entrancy attacks
    ForceFieldLib.requireBuildsAllowed(playerEntityId, baseEntityId, buildObjectTypeId, coords, extraData);

    return baseEntityId;
  }

  function jumpBuildWithExtraData(ObjectTypeId buildObjectTypeId, bytes memory extraData) public payable {
    (EntityId playerEntityId, VoxelCoord memory playerCoord, ) = requireValidPlayer(_msgSender());

    VoxelCoord[] memory moveCoords = new VoxelCoord[](1);
    moveCoords[0] = VoxelCoord(playerCoord.x, playerCoord.y + 1, playerCoord.z);
    MoveLib.movePlayer(playerEntityId, playerCoord, moveCoords);
    notify(playerEntityId, MoveNotifData({ moveCoords: moveCoords }));

    buildWithExtraData(buildObjectTypeId, playerCoord, extraData);
  }

  function jumpBuild(ObjectTypeId buildObjectTypeId) public payable {
    jumpBuildWithExtraData(buildObjectTypeId, new bytes(0));
  }

  function build(ObjectTypeId buildObjectTypeId, VoxelCoord memory baseCoord) public payable returns (EntityId) {
    return buildWithExtraData(buildObjectTypeId, baseCoord, new bytes(0));
  }
}
