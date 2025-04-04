// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Action } from "../codegen/common.sol";
import { Inventory } from "../codegen/tables/Inventory.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Player } from "../codegen/tables/Player.sol";
import { TotalBurnedOreCount } from "../codegen/tables/TotalBurnedOreCount.sol";
import { TotalMinedOreCount } from "../codegen/tables/TotalMinedOreCount.sol";

import { MinedOrePosition, OreCommitment, Position, ReversePosition } from "../utils/Vec3Storage.sol";

import { CHUNK_COMMIT_EXPIRY_BLOCKS, CHUNK_COMMIT_HALF_WIDTH, RESPAWN_ORE_BLOCK_RANGE } from "../Constants.sol";
import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { Vec3 } from "../Vec3.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";

contract OreSystem is System {
  function oreChunkCommit(EntityId caller, Vec3 chunkCoord) public {
    caller.activate();

    Vec3 callerChunkCoord = caller.getPosition().toChunkCoord();
    require(callerChunkCoord.inSurroundingCube(chunkCoord, CHUNK_COMMIT_HALF_WIDTH), "Not in commit range");

    // Check existing commitment
    uint256 commitment = OreCommitment._get(chunkCoord);
    require(block.number > commitment + CHUNK_COMMIT_EXPIRY_BLOCKS, "Existing ore commitment");

    // Commit starting from next block
    OreCommitment._set(chunkCoord, block.number + 1);
  }

  function respawnOre(uint256 blockNumber) public {
    require(
      blockNumber < block.number && blockNumber >= block.number - RESPAWN_ORE_BLOCK_RANGE,
      "Can only choose past 10 blocks"
    );

    uint256 burned = TotalBurnedOreCount._get();
    require(burned > 0, "No ores available for respawn");

    uint256 mined = TotalMinedOreCount._get();
    uint256 minedOreIdx = uint256(blockhash(blockNumber)) % mined;

    Vec3 oreCoord = MinedOrePosition._get(minedOreIdx);

    // Check existing entity
    EntityId entityId = ReversePosition._get(oreCoord);
    ObjectTypeId objectTypeId = ObjectType._get(entityId);
    require(objectTypeId == ObjectTypes.Air, "Ore coordinate is not air");
    require(Inventory._length(entityId) == 0, "Cannot respawn where there are dropped objects");

    // Remove from mined ore array
    if (minedOreIdx < mined) {
      Vec3 last = MinedOrePosition._get(mined - 1);
      MinedOrePosition._set(minedOreIdx, last);
    }
    MinedOrePosition._deleteRecord(mined - 1);

    // Update total amounts
    TotalBurnedOreCount._set(burned - 1);
    TotalMinedOreCount._set(mined - 1);

    // This is enough to respawn the ore block, as it will be read from the original terrain next time
    ObjectType._deleteRecord(entityId);
    Position._deleteRecord(entityId);
    ReversePosition._deleteRecord(oreCoord);
  }
}
