// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { inSurroundingCube, voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { callInternalSystem } from "@biomesaw/utils/src/CallUtils.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Player } from "../codegen/tables/Player.sol";
import { ObjectTypeSchema, ObjectTypeSchemaData } from "../codegen/tables/ObjectTypeSchema.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Position } from "../codegen/tables/Position.sol";
import { LastKnownPosition } from "../codegen/tables/LastKnownPosition.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Chip, ChipData } from "../codegen/tables/Chip.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";
import { TerrainCommitment, TerrainCommitmentData } from "../codegen/tables/TerrainCommitment.sol";
import { Commitment } from "../codegen/tables/Commitment.sol";
import { BlockPrevrandao } from "../codegen/tables/BlockPrevrandao.sol";

import { MAX_PLAYER_STAMINA, MAX_PLAYER_INFLUENCE_HALF_WIDTH, PLAYER_HAND_DAMAGE } from "../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID, AnyOreObjectID, LavaObjectID } from "../ObjectTypeIds.sol";
import { callGravity, inWorldBorder, inSpawnArea, getTerrainObjectTypeId, getTerrainAndOreObjectTypeId, getUniqueEntity, callMintXP, positionDataToVoxelCoord, lastKnownPositionDataToVoxelCoord, getRandomNumberBetween0And99 } from "../Utils.sol";
import { addToInventoryCount, useEquipped } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence, regenStamina } from "../utils/PlayerUtils.sol";
import { updateChipBatteryLevel } from "../utils/ChipUtils.sol";

import { IForceFieldSystem } from "../codegen/world/IForceFieldSystem.sol";
import { IMineHelperSystem } from "../codegen/world/IMineHelperSystem.sol";

contract OreSystem is System {
  function initiateOreReveal(VoxelCoord memory coord) public {
    require(inWorldBorder(coord), "Cannot reveal ore outside world border");

    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, coord);
    if (TerrainCommitment._getBlockNumber(coord.x, coord.y, coord.z) != 0) {
      revealOre(coord);
      return;
    }

    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    require(entityId == bytes32(0), "OreSystem: ore already revealed");
    uint16 mineObjectTypeId = getTerrainObjectTypeId(coord);
    require(mineObjectTypeId == AnyOreObjectID, "OreSystem: terrain is not an ore");

    TerrainCommitment._set(coord.x, coord.y, coord.z, block.number, playerEntityId);
    Commitment._set(playerEntityId, true, coord.x, coord.y, coord.z);
    BlockPrevrandao._set(block.number, block.prevrandao);

    callMintXP(playerEntityId, initialGas, 1);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.InitiateOreReveal,
        entityId: playerEntityId,
        objectTypeId: mineObjectTypeId,
        coordX: coord.x,
        coordY: coord.y,
        coordZ: coord.z,
        amount: block.number
      })
    );
  }

  // Can be called by anyone
  function revealOre(VoxelCoord memory coord) public returns (uint16) {
    TerrainCommitmentData memory terrainCommitmentData = TerrainCommitment._get(coord.x, coord.y, coord.z);
    require(terrainCommitmentData.blockNumber != 0, "OreSystem: terrain commitment not found");

    uint256 randomNumber = getRandomNumberBetween0And99(terrainCommitmentData.blockNumber);

    (uint16 mineObjectTypeId, uint16 oreObjectTypeId) = getTerrainAndOreObjectTypeId(coord, randomNumber);
    require(mineObjectTypeId == AnyOreObjectID, "OreSystem: terrain is not an ore");

    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    require(entityId == bytes32(0), "OreSystem: ore already revealed");
    entityId = getUniqueEntity();

    Position._set(entityId, coord.x, coord.y, coord.z);
    ReversePosition._set(coord.x, coord.y, coord.z, entityId);
    ObjectType._set(entityId, oreObjectTypeId);

    if (oreObjectTypeId == LavaObjectID) {
      // Apply consequences of lava
      if (ObjectType._get(terrainCommitmentData.committerEntityId) == PlayerObjectID) {
        VoxelCoord memory committerCoord = PlayerMetadata._getIsLoggedOff(terrainCommitmentData.committerEntityId)
          ? lastKnownPositionDataToVoxelCoord(LastKnownPosition._get(terrainCommitmentData.committerEntityId))
          : positionDataToVoxelCoord(Position._get(terrainCommitmentData.committerEntityId));
        uint32 currentStamina = regenStamina(terrainCommitmentData.committerEntityId, committerCoord);

        uint32 staminaRequired = MAX_PLAYER_STAMINA / 2;
        uint32 newStamina = currentStamina > staminaRequired ? currentStamina - staminaRequired : 0;
        Stamina._set(terrainCommitmentData.committerEntityId, block.timestamp, newStamina);

        PlayerActionNotif._set(
          terrainCommitmentData.committerEntityId,
          PlayerActionNotifData({
            actionType: ActionType.RevealOre,
            entityId: terrainCommitmentData.committerEntityId,
            objectTypeId: oreObjectTypeId,
            coordX: coord.x,
            coordY: coord.y,
            coordZ: coord.z,
            amount: 0
          })
        );
      } // else: the player died, no need to do anything
    }

    // Clear commitment data
    TerrainCommitment._deleteRecord(coord.x, coord.y, coord.z);
    Commitment._deleteRecord(terrainCommitmentData.committerEntityId);

    bytes32 playerEntityId = Player._get(_msgSender());
    if (playerEntityId != bytes32(0)) {
      PlayerActionNotif._set(
        playerEntityId,
        PlayerActionNotifData({
          actionType: ActionType.RevealOre,
          entityId: terrainCommitmentData.committerEntityId,
          objectTypeId: oreObjectTypeId,
          coordX: coord.x,
          coordY: coord.y,
          coordZ: coord.z,
          amount: terrainCommitmentData.blockNumber
        })
      );
    }

    return oreObjectTypeId;
  }
}
