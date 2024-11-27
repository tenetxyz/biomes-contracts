// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

struct VoxelCoord {
  int16 x;
  int16 y;
  int16 z;
}

enum Rotation {
  Z_NEG,
  X_NEG,
  Z_POS,
  X_POS
}
