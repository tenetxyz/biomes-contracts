// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Position } from "./codegen/tables/Position.sol";
import { ReversePosition } from "./codegen/tables/ReversePosition.sol";
import { Direction } from "./codegen/common.sol";
import { CHUNK_SIZE, FORCE_FIELD_SHARD_DIM, LOCAL_ENERGY_POOL_SHARD_DIM } from "./Constants.sol";

// Vec3 stores 3 packed int32 values (x, y, z)
type Vec3 is uint96;

function vec3(int32 _x, int32 _y, int32 _z) pure returns (Vec3) {
  // Pack 3 int32 values into a single uint96
  return Vec3.wrap((uint96(uint32(_z)) << 64) | (uint96(uint32(_y)) << 32) | uint96(uint32(_x)));
}

function eq(Vec3 a, Vec3 b) pure returns (bool) {
  return Vec3.unwrap(a) == Vec3.unwrap(b);
}

function neq(Vec3 a, Vec3 b) pure returns (bool) {
  return Vec3.unwrap(a) != Vec3.unwrap(b);
}

function add(Vec3 a, Vec3 b) pure returns (Vec3) {
  return vec3(a.x() + b.x(), a.y() + b.y(), a.z() + b.z());
}

function sub(Vec3 a, Vec3 b) pure returns (Vec3) {
  return vec3(a.x() - b.x(), a.y() - b.y(), a.z() - b.z());
}

function getDirectionVector(Direction direction) pure returns (Vec3) {
  if (direction == Direction.PositiveX) return vec3(1, 0, 0);
  if (direction == Direction.NegativeX) return vec3(-1, 0, 0);
  if (direction == Direction.PositiveY) return vec3(0, 1, 0);
  if (direction == Direction.NegativeY) return vec3(0, -1, 0);
  if (direction == Direction.PositiveZ) return vec3(0, 0, 1);
  if (direction == Direction.NegativeZ) return vec3(0, 0, -1);

  if (direction == Direction.PositiveXPositiveY) return vec3(1, 1, 0);
  if (direction == Direction.PositiveXNegativeY) return vec3(1, -1, 0);
  if (direction == Direction.NegativeXPositiveY) return vec3(-1, 1, 0);
  if (direction == Direction.NegativeXNegativeY) return vec3(-1, -1, 0);

  if (direction == Direction.PositiveXPositiveZ) return vec3(1, 0, 1);
  if (direction == Direction.PositiveXNegativeZ) return vec3(1, 0, -1);
  if (direction == Direction.NegativeXPositiveZ) return vec3(-1, 0, 1);
  if (direction == Direction.NegativeXNegativeZ) return vec3(-1, 0, -1);

  if (direction == Direction.PositiveYPositiveZ) return vec3(0, 1, 1);
  if (direction == Direction.PositiveYNegativeZ) return vec3(0, 1, -1);
  if (direction == Direction.NegativeYPositiveZ) return vec3(0, -1, 1);
  if (direction == Direction.NegativeYNegativeZ) return vec3(0, -1, -1);

  if (direction == Direction.PositiveXPositiveYPositiveZ) return vec3(1, 1, 1);
  if (direction == Direction.PositiveXPositiveYNegativeZ) return vec3(1, 1, -1);
  if (direction == Direction.PositiveXNegativeYPositiveZ) return vec3(1, -1, 1);
  if (direction == Direction.PositiveXNegativeYNegativeZ) return vec3(1, -1, -1);
  if (direction == Direction.NegativeXPositiveYPositiveZ) return vec3(-1, 1, 1);
  if (direction == Direction.NegativeXPositiveYNegativeZ) return vec3(-1, 1, -1);
  if (direction == Direction.NegativeXNegativeYPositiveZ) return vec3(-1, -1, 1);
  if (direction == Direction.NegativeXNegativeYNegativeZ) return vec3(-1, -1, -1);

  revert("Invalid direction");
}

library Vec3Lib {
  function x(Vec3 a) internal pure returns (int32) {
    // Extract x component (rightmost 32 bits)
    return int32(uint32(Vec3.unwrap(a) & 0xFFFFFFFF));
  }

  function y(Vec3 a) internal pure returns (int32) {
    // Extract y component (middle 32 bits)
    return int32(uint32((Vec3.unwrap(a) >> 32) & 0xFFFFFFFF));
  }

  function z(Vec3 a) internal pure returns (int32) {
    // Extract z component (leftmost 32 bits)
    return int32(uint32((Vec3.unwrap(a) >> 64) & 0xFFFFFFFF));
  }

  function mul(Vec3 a, int32 scalar) internal pure returns (Vec3) {
    return vec3(x(a) * scalar, y(a) * scalar, z(a) * scalar);
  }

  function div(Vec3 a, int32 scalar) internal pure returns (Vec3) {
    require(scalar != 0, "Division by zero");
    return vec3(x(a) / scalar, y(a) / scalar, z(a) / scalar);
  }

  function floorDiv(Vec3 a, int32 divisor) internal pure returns (Vec3) {
    require(divisor != 0, "Division by zero");

    return vec3(_floorDiv(x(a), divisor), _floorDiv(y(a), divisor), _floorDiv(z(a), divisor));
  }

  function neg(Vec3 a) internal pure returns (Vec3) {
    return vec3(-x(a), -y(a), -z(a));
  }

  function manhattanDistance(Vec3 a, Vec3 b) internal pure returns (int64) {
    return int64(abs(x(a) - x(b)) + abs(y(a) - y(b)) + abs(z(a) - z(b)));
  }

  function chebyshevDistance(Vec3 a, Vec3 b) internal pure returns (int32) {
    int32 dx = abs(x(a) - x(b));
    int32 dy = abs(y(a) - y(b));
    int32 dz = abs(z(a) - z(b));

    return max3(dx, dy, dz);
  }

  function getNeighbor(Vec3 self, Direction direction) internal pure returns (Vec3) {
    return self + getDirectionVector(direction);
  }

  function neighbors6(Vec3 a) internal pure returns (Vec3[6] memory) {
    Vec3[6] memory result;

    // Positive and negative directions along each axis
    for (uint8 i = 0; i < 6; i++) {
      result[i] = a.getNeighbor(Direction(i)); // +x
    }

    return result;
  }

  function neighbors26(Vec3 a) internal pure returns (Vec3[26] memory) {
    Vec3[26] memory result;

    // Generate all neighbors in a 3x3x3 cube, excluding the center
    for (uint8 i = 0; i <= 26; i++) {
      result[i] = a.getNeighbor(Direction(i));
    }

    return result;
  }

  function rotate(Vec3 self, Direction direction) internal pure returns (Vec3) {
    // Default facing direction is North (Positive Z)
    if (direction == Direction.PositiveZ) {
      return self; // No rotation needed for default facing direction
    } else if (direction == Direction.PositiveX) {
      // 90 degree rotation clockwise around Y axis
      return vec3(self.z(), self.y(), -self.x());
    } else if (direction == Direction.NegativeZ) {
      // 180 degree rotation around Y axis
      return vec3(-self.x(), self.y(), -self.z());
    } else if (direction == Direction.NegativeX) {
      // 260 degree rotation around Y axis
      return vec3(-self.z(), self.y(), self.x());
    }

    revert("Direction not supported for rotation");
  }

  function inSurroundingCube(Vec3 self, Vec3 other, int32 radius) internal pure returns (bool) {
    return chebyshevDistance(self, other) <= radius;
  }

  // Function to get the new Vec3 based on the direction
  function transform(Vec3 self, Direction direction) internal pure returns (Vec3) {
    return self + getDirectionVector(direction);
  }

  function inVonNeumannNeighborhood(Vec3 center, Vec3 checkCoord) internal pure returns (bool) {
    return center.manhattanDistance(checkCoord) == 1;
  }

  function toChunkCoord(Vec3 a) internal pure returns (Vec3) {
    return a.floorDiv(CHUNK_SIZE);
  }

  function toShardCoord(Vec3 self, int32 shardDim, bool ignoreY) internal pure returns (Vec3) {
    return
      vec3(
        _floorDiv(self.x(), shardDim),
        ignoreY ? int32(0) : _floorDiv(self.y(), shardDim),
        _floorDiv(self.z(), shardDim)
      );
  }

  function toForceFieldShardCoord(Vec3 coord) internal pure returns (Vec3) {
    return toShardCoord(coord, FORCE_FIELD_SHARD_DIM, false);
  }

  // Note: Local Energy Pool shards are 2D for now, but the table supports 3D
  // Thats why the Y is ignored, and 0 in the util functions
  function toLocalEnergyPoolShardCoord(Vec3 coord) internal pure returns (Vec3) {
    return toShardCoord(coord, LOCAL_ENERGY_POOL_SHARD_DIM, true);
  }

  function toString(Vec3 a) internal pure returns (string memory) {
    return string(abi.encodePacked("(", intToString(x(a)), ",", intToString(y(a)), ",", intToString(z(a)), ")"));
  }
}

using Vec3Lib for Vec3 global;
using { eq as ==, neq as !=, add as +, sub as - } for Vec3 global;

// ======== Helper Functions ========

function abs(int32 val) pure returns (int32) {
  return val >= 0 ? val : -val;
}

function max3(int32 a, int32 b, int32 c) pure returns (int32) {
  return a > b ? (a > c ? a : c) : (b > c ? b : c);
}

function min3(int32 a, int32 b, int32 c) pure returns (int32) {
  return a < b ? (a < c ? a : c) : (b < c ? b : c);
}

function intToString(int32 value) pure returns (string memory) {
  if (value == 0) {
    return "0";
  }

  bool negative = value < 0;
  uint32 absValue = negative ? uint32(-value) : uint32(value);

  // Calculate number of digits
  uint32 temp = absValue;
  uint8 digits = 0;
  while (temp > 0) {
    digits++;
    temp /= 10;
  }

  bytes memory buffer = new bytes(negative ? digits + 1 : digits);

  if (negative) {
    buffer[0] = "-";
  }

  temp = absValue;
  for (uint8 i = 0; i < digits; i++) {
    buffer[negative ? digits - i : digits - i - 1] = bytes1(uint8(48 + (temp % 10)));
    temp /= 10;
  }

  return string(buffer);
}

// Floor division (integer division that rounds down)
function _floorDiv(int32 a, int32 b) pure returns (int32) {
  require(b != 0, "Division by zero");

  // Handle special case for negative numbers
  if ((a < 0) != (b < 0) && a % b != 0) {
    return a / b - 1;
  }

  return a / b;
}
