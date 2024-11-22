// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { Orientation, OrientationData } from "../codegen/tables/Orientation.sol";

import { buildObjectAtCoordWithOrientation } from "../utils/BuildUtils.sol";

contract OrientationSystem is System {
  function buildWithOrientationWithExtraData(
    uint8 objectTypeId,
    VoxelCoord memory coord,
    OrientationData memory orientation,
    bytes memory extraData
  ) public payable returns (bytes32) {
    return buildObjectAtCoordWithOrientation(objectTypeId, coord, orientation, extraData);
  }

  function buildWithOrientation(
    uint8 objectTypeId,
    VoxelCoord memory coord,
    OrientationData memory orientation
  ) public payable returns (bytes32) {
    return buildWithOrientationWithExtraData(objectTypeId, coord, orientation, new bytes(0));
  }
}
