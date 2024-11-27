// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord, Rotation } from "@biomesaw/utils/src/Types.sol";
import { OrientationData } from "../codegen/tables/Orientation.sol";

int32 constant PI_SCALED = 3.1416 * 10_000;

function rotationToOrientation(Rotation rotation) pure returns (OrientationData memory) {
  int32 angle = (int32(uint32(rotation)) * PI_SCALED) / 2;
  return OrientationData({ pitch: 0, yaw: angle });
}

function orientationToRotation(OrientationData memory orientation) pure returns (Rotation) {
  int32 rotationIndex = (orientation.yaw * 2) / PI_SCALED;

  // Normalize to 0-3 range
  uint8 normalized = uint8(((uint32(rotationIndex) % 4) + 4) % 4);

  return Rotation(normalized);
}

function getRelativeCoord(
  VoxelCoord memory baseCoord,
  Rotation rotation,
  VoxelCoord memory offset
) pure returns (VoxelCoord memory) {
  if (rotation == Rotation.Z_NEG || rotation == Rotation.Z_POS) {
    return VoxelCoord(baseCoord.x + offset.x, baseCoord.y + offset.y, baseCoord.z + offset.z);
  } else {
    return VoxelCoord(baseCoord.x + offset.z, baseCoord.y + offset.y, baseCoord.z + offset.x);
  }
}
