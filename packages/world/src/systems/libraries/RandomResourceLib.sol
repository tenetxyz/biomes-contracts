// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { LibPRNG } from "solady/utils/LibPRNG.sol";

import { ResourceCategory } from "../../codegen/common.sol";
import { ResourceCount } from "../../codegen/tables/ResourceCount.sol";
import { TotalResourceCount } from "../../codegen/tables/TotalResourceCount.sol";

import { ChunkCommitment, ResourcePosition } from "../../utils/Vec3Storage.sol";

import { CHUNK_COMMIT_EXPIRY_BLOCKS } from "../../Constants.sol";
import { EntityId } from "../../EntityId.sol";
import { ObjectTypeId } from "../../ObjectTypeId.sol";
import { ObjectTypes } from "../../ObjectTypes.sol";
import { ResourceLib } from "../../ResourceLib.sol";
import { Vec3 } from "../../Vec3.sol";

import { Mass } from "../../codegen/tables/Mass.sol";
import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../../codegen/tables/ObjectTypeMetadata.sol";

library RandomResourceLib {
  using LibPRNG for LibPRNG.PRNG;

  function _getRandomResourceType(Vec3 coord, ResourceCategory category) public view returns (ObjectTypeId, uint256) {
    Vec3 chunkCoord = coord.toChunkCoord();
    uint256 commitment = ChunkCommitment._get(chunkCoord);
    // We can't get blockhash of current block
    require(block.number > commitment, "Not within commitment blocks");
    require(block.number <= commitment + CHUNK_COMMIT_EXPIRY_BLOCKS, "Chunk commitment expired");

    return ResourceLib.getRandomResource(category, coord, commitment);
  }

  function _mineRandomResource(EntityId entityId, Vec3 coord, ResourceCategory category) public returns (ObjectTypeId) {
    (ObjectTypeId resourceType, uint256 resourceCount) = _getRandomResourceType(coord, category);

    // Set total harvested resource and add position
    uint256 totalResources = TotalResourceCount._get(category);
    ResourcePosition._set(category, totalResources, coord);
    TotalResourceCount._set(category, totalResources + 1);

    ResourceCount._set(resourceType, resourceCount);
    ObjectType._set(entityId, resourceType);
    Mass._setMass(entityId, ObjectTypeMetadata._getMass(resourceType));

    return resourceType;
  }
}
