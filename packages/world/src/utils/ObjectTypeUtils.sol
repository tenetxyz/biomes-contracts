// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "../VoxelCoord.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";

function getObjectTypeSchema(ObjectTypeId objectTypeId) pure returns (VoxelCoord[] memory) {
  if (objectTypeId == ObjectTypes.Player) {
    VoxelCoord[] memory playerRelativePositions = new VoxelCoord[](1);
    playerRelativePositions[0] = VoxelCoord(0, 1, 0);
    return playerRelativePositions;
  }

  if (objectTypeId == ObjectTypes.Bed) {
    VoxelCoord[] memory bedRelativePositions = new VoxelCoord[](1);
    bedRelativePositions[0] = VoxelCoord(0, 0, 1);
    return bedRelativePositions;
  }

  if (objectTypeId == ObjectTypes.TextSign || objectTypeId == ObjectTypes.SmartTextSign) {
    VoxelCoord[] memory textSignRelativePositions = new VoxelCoord[](1);
    textSignRelativePositions[0] = VoxelCoord(0, 1, 0);
    return textSignRelativePositions;
  }

  return new VoxelCoord[](0);
}
