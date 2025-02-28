// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "../VoxelCoord.sol";

import { PlayerObjectID, TextSignObjectID, SmartTextSignObjectID, BedObjectID } from "../ObjectType.sol";

import { ObjectType } from "../ObjectType.sol";

function getObjectTypeSchema(ObjectType objectType) pure returns (VoxelCoord[] memory) {
  if (objectType == PlayerObjectID) {
    VoxelCoord[] memory playerRelativePositions = new VoxelCoord[](1);
    playerRelativePositions[0] = VoxelCoord(0, 1, 0);
    return playerRelativePositions;
  }

  if (objectType == BedObjectID) {
    VoxelCoord[] memory bedRelativePositions = new VoxelCoord[](1);
    bedRelativePositions[0] = VoxelCoord(0, 0, 1);
    return bedRelativePositions;
  }

  if (objectType == TextSignObjectID || objectType == SmartTextSignObjectID) {
    VoxelCoord[] memory textSignRelativePositions = new VoxelCoord[](1);
    textSignRelativePositions[0] = VoxelCoord(0, 1, 0);
    return textSignRelativePositions;
  }

  return new VoxelCoord[](0);
}
