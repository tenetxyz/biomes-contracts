// // SPDX-License-Identifier: MIT
// pragma solidity >=0.8.24;
//
// import { EntityId } from "../src/EntityId.sol";
//
// import { ResourceCategory } from "../src/codegen/common.sol";
// import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
//
// import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
// import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
// import { ResourceCount } from "../src/codegen/tables/ResourceCount.sol";
//
// import { BurnedResourceCount } from "../src/codegen/tables/BurnedResourceCount.sol";
// import { TotalResourceCount } from "../src/codegen/tables/TotalResourceCount.sol";
// import { WorldStatus } from "../src/codegen/tables/WorldStatus.sol";
// import { DustTest } from "./DustTest.sol";
//
// import {
//   ChunkCommitment, LocalEnergyPool, Position, ResourcePosition, ReversePosition
// } from "../src/utils/Vec3Storage.sol";
//
// import { CHUNK_COMMIT_EXPIRY_BLOCKS, CHUNK_SIZE } from "../src/Constants.sol";
// import { ObjectTypeId } from "../src/ObjectTypeId.sol";
// import { ObjectTypeLib } from "../src/ObjectTypeLib.sol";
// import { ObjectTypes } from "../src/ObjectTypes.sol";
// import { Vec3, vec3 } from "../src/Vec3.sol";
// import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
//
// contract ResourceTest is DustTest {
//   using ObjectTypeLib for ObjectTypeId;
//
//   function exploreChunk(Vec3 coord) internal {
//     Vec3 chunkCoord = coord.toChunkCoord();
//
//     address chunkPtr = TerrainLib._getChunkPointer(chunkCoord, worldAddress);
//
//     // Set chunk's code to non zero
//     bytes memory chunkData = hex"00";
//     vm.etch(chunkPtr, chunkData);
//   }
//
//   function addResourcePosition(ResourceCategory category, Vec3 coord) internal {
//     uint256 count = TotalResourceCount.get(category);
//     TotalResourceCount.set(category, count + 1);
//     ResourcePosition.set(category, count, coord);
//   }
//
//   function testChunkCommit() public {
//     Vec3 coord = vec3(0, 0, 0);
//     Vec3 chunkCoord = coord.toChunkCoord();
//     exploreChunk(coord);
//
//     (address alice, EntityId aliceEntityId) = createTestPlayer(coord);
//
//     vm.prank(alice);
//     world.chunkCommit(aliceEntityId, chunkCoord);
//
//     assertEq(ChunkCommitment.get(chunkCoord), block.number + 1);
//   }
//
//   function testChunkCommitCannotCommitIfExisting() public {
//     Vec3 coord = vec3(0, 0, 0);
//     Vec3 chunkCoord = coord.toChunkCoord();
//     exploreChunk(coord);
//
//     (address alice, EntityId aliceEntityId) = createTestPlayer(coord);
//
//     vm.prank(alice);
//     world.chunkCommit(aliceEntityId, chunkCoord);
//
//     vm.roll(block.number + 1 + CHUNK_COMMIT_EXPIRY_BLOCKS);
//
//     vm.prank(alice);
//     vm.expectRevert("Existing chunk commitment");
//     world.chunkCommit(aliceEntityId, chunkCoord);
//
//     // Next block it should be possible to commit
//     vm.roll(block.number + 1);
//     vm.prank(alice);
//     world.chunkCommit(aliceEntityId, chunkCoord);
//
//     assertEq(ChunkCommitment.get(chunkCoord), block.number + 1);
//   }
//
//   function testRespawnResource() public {
//     Vec3 resourceCoord = vec3(0, 0, 0);
//     ResourceCategory category = ResourceCategory.Mining;
//
//     addResourcePosition(category, resourceCoord);
//
//     // Burn resource so it becomes available to respawn
//     BurnedResourceCount.set(category, 1);
//
//     // Set coord to air
//     EntityId entityId = randomEntityId();
//     ReversePosition.set(resourceCoord, entityId);
//     ObjectType.set(entityId, ObjectTypes.Air);
//
//     address alice = vm.randomAddress();
//
//     vm.prank(alice);
//     world.respawnResource(block.number - 1, category);
//
//     assertEq(TotalResourceCount.get(category), 0);
//     assertEq(BurnedResourceCount.get(category), 0);
//
//     // Check that the air entity was removed
//     assertTrue(ObjectType.get(entityId).isNull());
//   }
//
//   function testRespawnResourceFailsIfNoBurned() public {
//     Vec3 resourceCoord = vec3(0, 0, 0);
//     ResourceCategory category = ResourceCategory.Mining;
//
//     addResourcePosition(category, resourceCoord);
//
//     // Set coord to air
//     EntityId entityId = randomEntityId();
//     ReversePosition.set(resourceCoord, entityId);
//     ObjectType.set(entityId, ObjectTypes.Air);
//
//     address alice = vm.randomAddress();
//
//     vm.prank(alice);
//     vm.expectRevert("No resources available for respawn");
//     world.respawnResource(block.number - 1, category);
//   }
// }
