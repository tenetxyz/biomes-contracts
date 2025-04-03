// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Action } from "../codegen/common.sol";
import { InventoryObjects } from "../codegen/tables/InventoryObjects.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Player } from "../codegen/tables/Player.sol";
import { TotalBurnedResourceCount } from "../codegen/tables/TotalBurnedResourceCount.sol";
import { TotalResourceCount } from "../codegen/tables/TotalResourceCount.sol";

import { ChunkCommitment, Position, ResourcePosition, ReversePosition } from "../utils/Vec3Storage.sol";

import { CHUNK_COMMIT_EXPIRY_BLOCKS, CHUNK_COMMIT_HALF_WIDTH, RESPAWN_ORE_BLOCK_RANGE } from "../Constants.sol";
import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";

import { Vec3 } from "../Vec3.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";

contract NatureSystem is System {
  function chunkCommit(EntityId caller, Vec3 chunkCoord) public {
    caller.activate();

    Vec3 callerChunkCoord = caller.getPosition().toChunkCoord();
    require(callerChunkCoord.inSurroundingCube(chunkCoord, CHUNK_COMMIT_HALF_WIDTH), "Not in commit range");

    // Check existing commitment
    uint256 commitment = ChunkCommitment._get(chunkCoord);
    require(block.number > commitment + CHUNK_COMMIT_EXPIRY_BLOCKS, "Existing chunk commitment");

    // Commit starting from next block
    ChunkCommitment._set(chunkCoord, block.number + 1);
  }

  function respawnResource(uint256 blockNumber, ObjectTypeId objectType) public {
    require(
      blockNumber < block.number && blockNumber >= block.number - RESPAWN_ORE_BLOCK_RANGE,
      "Can only choose past 10 blocks"
    );

    uint256 burned = TotalBurnedResourceCount._get(objectType);
    require(burned > 0, "No resources available for respawn");

    uint256 collected = TotalResourceCount._get(objectType);
    uint256 resourceIdx = uint256(blockhash(blockNumber)) % collected;

    Vec3 resourceCoord = ResourcePosition._get(objectType, resourceIdx);

    // Check existing entity
    EntityId entityId = ReversePosition._get(resourceCoord);
    ObjectTypeId objectTypeId = ObjectType._get(entityId);
    require(objectTypeId == ObjectTypes.Air, "Resource coordinate is not air");
    require(InventoryObjects._lengthObjectTypeIds(entityId) == 0, "Cannot respawn where there are dropped objects");

    // Remove from collected resource array
    if (resourceIdx < collected) {
      Vec3 last = ResourcePosition._get(objectType, collected - 1);
      ResourcePosition._set(objectType, resourceIdx, last);
    }
    ResourcePosition._deleteRecord(objectType, collected - 1);

    // Update total amounts
    TotalBurnedResourceCount._set(objectType, burned - 1);
    TotalResourceCount._set(objectType, collected - 1);

    // This is enough to respawn the resource block, as it will be read from the original terrain next time
    ObjectType._deleteRecord(entityId);
    Position._deleteRecord(entityId);
    ReversePosition._deleteRecord(resourceCoord);
  }
}
