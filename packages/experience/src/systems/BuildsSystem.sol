// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { Builds, BuildsData } from "../codegen/tables/Builds.sol";
import { BuildsWithPos, BuildsWithPosData } from "../codegen/tables/BuildsWithPos.sol";
import { Build, BuildWithPos } from "../utils/BuildUtils.sol";

contract BuildsSystem is System {
  function setBuild(bytes32 buildId, string memory name, Build memory build) public {
    int16[] memory relativePositionsX = new int16[](build.relativePositions.length);
    int16[] memory relativePositionsY = new int16[](build.relativePositions.length);
    int16[] memory relativePositionsZ = new int16[](build.relativePositions.length);
    for (uint256 i = 0; i < build.relativePositions.length; i++) {
      relativePositionsX[i] = build.relativePositions[i].x;
      relativePositionsY[i] = build.relativePositions[i].y;
      relativePositionsZ[i] = build.relativePositions[i].z;
    }

    Builds.set(
      _msgSender(),
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

  function deleteBuild(bytes32 buildId) public {
    Builds.deleteRecord(_msgSender(), buildId);
  }

  function setBuildWithPos(bytes32 buildId, string memory name, BuildWithPos memory build) public {
    int16[] memory relativePositionsX = new int16[](build.relativePositions.length);
    int16[] memory relativePositionsY = new int16[](build.relativePositions.length);
    int16[] memory relativePositionsZ = new int16[](build.relativePositions.length);
    for (uint256 i = 0; i < build.relativePositions.length; i++) {
      relativePositionsX[i] = build.relativePositions[i].x;
      relativePositionsY[i] = build.relativePositions[i].y;
      relativePositionsZ[i] = build.relativePositions[i].z;
    }

    BuildsWithPos.set(
      _msgSender(),
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

  function deleteBuildWithPos(bytes32 buildId) public {
    BuildsWithPos.deleteRecord(_msgSender(), buildId);
  }
}
