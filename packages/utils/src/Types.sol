// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

struct VoxelCoord {
  int32 x;
  int32 y;
  int32 z;
}

// Define an enum representing all possible 3D movements in a Moore neighborhood
enum VoxelCoordDirection {
  PositiveX, // +1 in the x direction
  NegativeX, // -1 in the x direction
  PositiveY, // +1 in the y direction
  NegativeY, // -1 in the y direction
  PositiveZ, // +1 in the z direction
  NegativeZ, // -1 in the z direction
  PositiveXPositiveY, // +1 in x and +1 in y
  PositiveXNegativeY, // +1 in x and -1 in y
  PositiveXPositiveZ, // +1 in x and +1 in z
  PositiveXNegativeZ, // +1 in x and -1 in z
  NegativeXPositiveY, // -1 in x and +1 in y
  NegativeXNegativeY, // -1 in x and -1 in y
  NegativeXPositiveZ, // -1 in x and +1 in z
  NegativeXNegativeZ, // -1 in x and -1 in z
  PositiveYPositiveZ, // +1 in y and +1 in z
  PositiveYNegativeZ, // +1 in y and -1 in z
  NegativeYPositiveZ, // -1 in y and +1 in z
  NegativeYNegativeZ, // -1 in y and -1 in z
  PositiveXPositiveYPositiveZ, // +1 in x, +1 in y, +1 in z
  PositiveXPositiveYNegativeZ, // +1 in x, +1 in y, -1 in z
  PositiveXNegativeYPositiveZ, // +1 in x, -1 in y, +1 in z
  PositiveXNegativeYNegativeZ, // +1 in x, -1 in y, -1 in z
  NegativeXPositiveYPositiveZ, // -1 in x, +1 in y, +1 in z
  NegativeXPositiveYNegativeZ, // -1 in x, +1 in y, -1 in z
  NegativeXNegativeYPositiveZ, // -1 in x, -1 in y, +1 in z
  NegativeXNegativeYNegativeZ // -1 in x, -1 in y, -1 in z
}

// Define an enum representing all possible 3D movements in a Von Neumann neighborhood
enum VoxelCoordDirectionVonNeumann {
  PositiveX,
  NegativeX,
  PositiveY,
  NegativeY,
  PositiveZ,
  NegativeZ
}
