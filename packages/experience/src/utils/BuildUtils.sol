// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";
import { IWorld } from "@biomesaw/world/src/codegen/world/IWorld.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

import { getEntityAtCoord, getObjectType } from "./EntityUtils.sol";

import { Builds, BuildsData } from "../codegen/tables/Builds.sol";
import { BuildsWithPos, BuildsWithPosData } from "../codegen/tables/BuildsWithPos.sol";

struct Build {
  uint8[] objectTypeIds;
  VoxelCoord[] relativePositions;
}

struct BuildWithPos {
  uint8[] objectTypeIds;
  VoxelCoord[] relativePositions;
  VoxelCoord baseWorldCoord;
}

function getBuild(address experience, bytes32 buildId) view returns (Build memory) {
  BuildsData memory buildData = Builds.get(experience, buildId);

  VoxelCoord[] memory relativePositions = new VoxelCoord[](buildData.relativePositionsX.length);
  for (uint256 i = 0; i < buildData.relativePositionsX.length; i++) {
    relativePositions[i] = VoxelCoord(
      buildData.relativePositionsX[i],
      buildData.relativePositionsY[i],
      buildData.relativePositionsZ[i]
    );
  }

  return Build({ objectTypeIds: buildData.objectTypeIds, relativePositions: relativePositions });
}

function getBuildWithPos(address experience, bytes32 buildId) view returns (BuildWithPos memory) {
  BuildsWithPosData memory buildData = BuildsWithPos.get(experience, buildId);

  VoxelCoord[] memory relativePositions = new VoxelCoord[](buildData.relativePositionsX.length);
  for (uint256 i = 0; i < buildData.relativePositionsX.length; i++) {
    relativePositions[i] = VoxelCoord(
      buildData.relativePositionsX[i],
      buildData.relativePositionsY[i],
      buildData.relativePositionsZ[i]
    );
  }

  return
    BuildWithPos({
      objectTypeIds: buildData.objectTypeIds,
      relativePositions: relativePositions,
      baseWorldCoord: VoxelCoord(buildData.baseWorldCoordX, buildData.baseWorldCoordY, buildData.baseWorldCoordZ)
    });
}

function buildExistsInWorld(Build memory buildData, VoxelCoord memory baseWorldCoord) view returns (bool) {
  // Go through each relative position, apply it to the base world coord, and check if the object type id matches
  for (uint256 i = 0; i < buildData.objectTypeIds.length; i++) {
    VoxelCoord memory absolutePosition = VoxelCoord({
      x: baseWorldCoord.x + buildData.relativePositions[i].x,
      y: baseWorldCoord.y + buildData.relativePositions[i].y,
      z: baseWorldCoord.z + buildData.relativePositions[i].z
    });
    bytes32 entityId = getEntityAtCoord(absolutePosition);

    uint16 objectTypeId;
    if (entityId == bytes32(0)) {
      // then it's the terrain
      objectTypeId = IWorld(WorldContextConsumerLib._world()).getTerrainBlock(absolutePosition);
    } else {
      objectTypeId = getObjectType(entityId);
    }
    if (objectTypeId != buildData.objectTypeIds[i]) {
      return false;
    }
  }

  return true;
}

function buildWithPosExistsInWorld(
  BuildWithPos memory buildData,
  VoxelCoord memory baseWorldCoord
) view returns (bool) {
  if (!voxelCoordsAreEqual(buildData.baseWorldCoord, baseWorldCoord)) {
    return false;
  }
  return
    buildExistsInWorld(
      Build({ objectTypeIds: buildData.objectTypeIds, relativePositions: buildData.relativePositions }),
      baseWorldCoord
    );
}
