// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "../VoxelCoord.sol";

import { PlayerObjectID, TextSignObjectID, SmartTextSignObjectID, BedObjectID } from "../ObjectTypeIds.sol";

import { ObjectTypeId } from "../ObjectTypeIds.sol";

function getObjectTypeSchema(ObjectTypeId objectTypeId) pure returns (VoxelCoord[] memory) {
  if (objectTypeId == PlayerObjectID) {
    VoxelCoord[] memory playerRelativePositions = new VoxelCoord[](1);
    playerRelativePositions[0] = VoxelCoord(0, 1, 0);
    return playerRelativePositions;
  }

  if (objectTypeId == BedObjectID) {
    VoxelCoord[] memory bedRelativePositions = new VoxelCoord[](1);
    bedRelativePositions[0] = VoxelCoord(1, 0, 0);
    return bedRelativePositions;
  }

  if (objectTypeId == TextSignObjectID || objectTypeId == SmartTextSignObjectID) {
    VoxelCoord[] memory textSignRelativePositions = new VoxelCoord[](1);
    textSignRelativePositions[0] = VoxelCoord(0, 1, 0);
    return textSignRelativePositions;
  }

  return new VoxelCoord[](0);
}
