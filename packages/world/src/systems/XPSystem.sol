// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { LastKnownPosition } from "../codegen/tables/LastKnownPosition.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Health } from "../codegen/tables/Health.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { ExperiencePoints } from "../codegen/tables/ExperiencePoints.sol";
import { BlockMetadata } from "../codegen/tables/BlockMetadata.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_RESPAWN_HALF_WIDTH, MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, PLAYER_HAND_DAMAGE, HIT_STAMINA_COST } from "../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID, ChestObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord, lastKnownPositionDataToVoxelCoord, gravityApplies, inWorldBorder, getTerrainObjectTypeId, getUniqueEntity } from "../Utils.sol";
import { useEquipped, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina, despawnPlayer } from "../utils/PlayerUtils.sol";
import { inSurroundingCube, inSurroundingCubeIgnoreY } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { calculateXPToBurnFromLogout, burnXP, safeBurnXP } from "../utils/XPUtils.sol";

contract XPSystem is System {
  function transferXP(bytes32 dstEntityId, uint256 transferAmount) public {
    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "XPSystem: player does not exist");
    require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "XPSystem: player isn't logged in");

    VoxelCoord memory playerCoord = positionDataToVoxelCoord(Position._get(playerEntityId));
    VoxelCoord memory dstCoord = positionDataToVoxelCoord(Position._get(dstEntityId));
    require(inSurroundingCube(playerCoord, 1, dstCoord), "XPSystem: destination out of range");

    regenHealth(playerEntityId);
    regenStamina(playerEntityId, playerCoord);

    uint8 dstObjectTypeId = ObjectType._get(dstEntityId);
    require(dstObjectTypeId == ChestObjectID, "XPSystem: cannot transfer to non-chest");
    address owner = BlockMetadata._getOwner(dstEntityId);
    uint256 currentDstXP = ExperiencePoints._get(dstEntityId);
    if (owner == address(0) || owner == _msgSender()) {
      burnXP(playerEntityId, transferAmount);
      // lock chest

      // Mint XP to chest without increasing total supply
      uint256 currentDstXP = ExperiencePoints._get(dstEntityId);
      ExperiencePoints._set(dstEntityId, currentDstXP + transferAmount);

      if (owner == address(0)) {
        BlockMetadata._setOwner(dstEntityId, _msgSender());
      }
    } else {
      // spend xp to unlock chest
      uint256 spendXP = currentDstXP > transferAmount ? transferAmount : currentDstXP;
      burnXP(playerEntityId, spendXP);

      // Burn XP from chest without decreasing total supply, as it was never increased
      uint256 newDstXP = currentDstXP - spendXP;
      if (newDstXP == 0) {
        ExperiencePoints._deleteRecord(dstEntityId);
        BlockMetadata._setOwner(dstEntityId, address(0));
      } else {
        ExperiencePoints._set(dstEntityId, newDstXP);
      }
    }
  }

  function updateLoggedOffXP(address player) public {
    bytes32 playerEntityId = Player._get(player);
    require(playerEntityId != bytes32(0), "XPSystem: player does not exist");
    require(PlayerMetadata._getIsLoggedOff(playerEntityId), "XPSystem: player already logged in");
    uint256 newXP = safeBurnXP(playerEntityId, calculateXPToBurnFromLogout(playerEntityId));
    require(newXP > 0, "XPSystem: if xp is 0, must enforce logout penalty");
  }

  function enforceLogoutPenalty(address player, VoxelCoord memory respawnCoord) public {
    bytes32 playerEntityId = Player._get(player);
    require(playerEntityId != bytes32(0), "XPSystem: player does not exist");
    require(PlayerMetadata._getIsLoggedOff(playerEntityId), "XPSystem: player already logged in");

    uint256 newXP = safeBurnXP(playerEntityId, calculateXPToBurnFromLogout(playerEntityId));
    if (newXP > 0) {
      return;
    }

    VoxelCoord memory lastKnownCoord = lastKnownPositionDataToVoxelCoord(LastKnownPosition._get(playerEntityId));
    require(inWorldBorder(respawnCoord), "XPSystem: cannot respawn outside world border");
    require(
      inSurroundingCubeIgnoreY(lastKnownCoord, MAX_PLAYER_RESPAWN_HALF_WIDTH, respawnCoord),
      "XPSystem: respawn coord too far from last known position"
    );

    bytes32 respawnEntityId = ReversePosition._get(respawnCoord.x, respawnCoord.y, respawnCoord.z);
    if (respawnEntityId == bytes32(0)) {
      // Check terrain block type
      uint8 terrainObjectTypeId = getTerrainObjectTypeId(respawnCoord);
      require(
        terrainObjectTypeId == AirObjectID || terrainObjectTypeId == WaterObjectID,
        "XPSystem: cannot respawn on terrain non-air block"
      );
    } else {
      require(ObjectType._get(respawnEntityId) == AirObjectID, "XPSystem: cannot respawn on non-air block");

      // Transfer any dropped items
      transferAllInventoryEntities(respawnEntityId, playerEntityId, PlayerObjectID);
      Position._deleteRecord(respawnEntityId);
    }

    Position._set(playerEntityId, respawnCoord.x, respawnCoord.y, respawnCoord.z);
    ReversePosition._set(respawnCoord.x, respawnCoord.y, respawnCoord.z, playerEntityId);
    LastKnownPosition._deleteRecord(playerEntityId);

    despawnPlayer(playerEntityId);
  }
}
