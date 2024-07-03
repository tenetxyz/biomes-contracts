// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

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

function setBuild(address experience, bytes32 buildId, string memory name, Build memory build) {
  int16[] memory relativePositionsX = new int16[](build.relativePositions.length);
  int16[] memory relativePositionsY = new int16[](build.relativePositions.length);
  int16[] memory relativePositionsZ = new int16[](build.relativePositions.length);
  for (uint256 i = 0; i < build.relativePositions.length; i++) {
    relativePositionsX[i] = build.relativePositions[i].x;
    relativePositionsY[i] = build.relativePositions[i].y;
    relativePositionsZ[i] = build.relativePositions[i].z;
  }
  Builds.set(
    experience,
    buildId,
    BuildsData({
      name: name,
      objectTypeIds: build.objectTypeIds,
      relativePositionsX: relativePositionsX,
      relativePositionsY: relativePositionsY,
      relativePositionsZ: relativePositionsZ
    })
  );
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

function setBuildWithPos(address experience, bytes32 buildId, string memory name, BuildWithPos memory build) {
  int16[] memory relativePositionsX = new int16[](build.relativePositions.length);
  int16[] memory relativePositionsY = new int16[](build.relativePositions.length);
  int16[] memory relativePositionsZ = new int16[](build.relativePositions.length);
  for (uint256 i = 0; i < build.relativePositions.length; i++) {
    relativePositionsX[i] = build.relativePositions[i].x;
    relativePositionsY[i] = build.relativePositions[i].y;
    relativePositionsZ[i] = build.relativePositions[i].z;
  }
  BuildsWithPos.set(
    experience,
    buildId,
    BuildsWithPosData({
      name: name,
      objectTypeIds: build.objectTypeIds,
      relativePositionsX: relativePositionsX,
      relativePositionsY: relativePositionsY,
      relativePositionsZ: relativePositionsZ,
      baseWorldCoordX: build.baseWorldCoord.x,
      baseWorldCoordY: build.baseWorldCoord.y,
      baseWorldCoordZ: build.baseWorldCoord.z
    })
  );
}

function buildExistsInWorld(
  address biomeWorldAddress,
  Build memory buildData,
  VoxelCoord memory baseWorldCoord
) view returns (bool) {
  // Go through each relative position, apply it to the base world coord, and check if the object type id matches
  for (uint256 i = 0; i < buildData.objectTypeIds.length; i++) {
    VoxelCoord memory absolutePosition = VoxelCoord({
      x: baseWorldCoord.x + buildData.relativePositions[i].x,
      y: baseWorldCoord.y + buildData.relativePositions[i].y,
      z: baseWorldCoord.z + buildData.relativePositions[i].z
    });
    bytes32 entityId = getEntityAtCoord(absolutePosition);

    uint8 objectTypeId;
    if (entityId == bytes32(0)) {
      // then it's the terrain
      objectTypeId = IWorld(biomeWorldAddress).getTerrainBlock(absolutePosition);
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
  address biomeWorldAddress,
  BuildWithPos memory buildData,
  VoxelCoord memory baseWorldCoord
) view returns (bool) {
  if (!voxelCoordsAreEqual(buildData.baseWorldCoord, baseWorldCoord)) {
    return false;
  }
  return
    buildExistsInWorld(
      biomeWorldAddress,
      Build({ objectTypeIds: buildData.objectTypeIds, relativePositions: buildData.relativePositions }),
      baseWorldCoord
    );
}
