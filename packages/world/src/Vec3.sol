// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { FixedPointMathLib } from "solady/utils/FixedPointMathLib.sol";
import { LibString } from "solady/utils/LibString.sol";

import { CHUNK_SIZE, FRAGMENT_SIZE, REGION_SIZE } from "./Constants.sol";
import { Direction } from "./codegen/common.sol";

// Vec3 stores 3 packed int32 values (x, y, z)
type Vec3 is uint96;

function vec3(int32 _x, int32 _y, int32 _z) pure returns (Vec3) {
  // Pack 3 int32 values into a single uint96
  return Vec3.wrap((uint96(uint32(_x)) << 64) | (uint96(uint32(_y)) << 32) | uint96(uint32(_z)));
}

function eq(Vec3 a, Vec3 b) pure returns (bool) {
  return Vec3.unwrap(a) == Vec3.unwrap(b);
}

function neq(Vec3 a, Vec3 b) pure returns (bool) {
  return Vec3.unwrap(a) != Vec3.unwrap(b);
}

function lt(Vec3 a, Vec3 b) pure returns (bool) {
  (int32 minX, int32 minY, int32 minZ) = a.xyz();
  (int32 maxX, int32 maxY, int32 maxZ) = b.xyz();
  return minX < maxX && minY < maxY && minZ < maxZ;
}

function leq(Vec3 a, Vec3 b) pure returns (bool) {
  (int32 minX, int32 minY, int32 minZ) = a.xyz();
  (int32 maxX, int32 maxY, int32 maxZ) = b.xyz();
  return minX <= maxX && minY <= maxY && minZ <= maxZ;
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
  using LibString for *;
  using FixedPointMathLib for *;

  function x(Vec3 a) internal pure returns (int32) {
    // Extract z component (leftmost 32 bits)
    return int32(uint32(Vec3.unwrap(a) >> 64));
  }

  function y(Vec3 a) internal pure returns (int32) {
    // Extract y component (middle 32 bits)
    return int32(uint32(Vec3.unwrap(a) >> 32));
  }

  function z(Vec3 a) internal pure returns (int32) {
    // Extract x component (rightmost 32 bits)
    return int32(uint32(Vec3.unwrap(a)));
  }

  function xyz(Vec3 self) internal pure returns (int32, int32, int32) {
    return (self.x(), self.y(), self.z());
  }

  function mul(Vec3 a, int32 scalar) internal pure returns (Vec3) {
    return vec3(x(a) * scalar, y(a) * scalar, z(a) * scalar);
  }

  function div(Vec3 a, int32 scalar) internal pure returns (Vec3) {
    require(scalar != 0, "Division by zero");
    return vec3(x(a) / scalar, y(a) / scalar, z(a) / scalar);
  }

  function mod(Vec3 a, int32 scalar) internal pure returns (Vec3) {
    return vec3(_mod(x(a), scalar), _mod(y(a), scalar), _mod(z(a), scalar));
  }

  function floorDiv(Vec3 a, int32 divisor) internal pure returns (Vec3) {
    require(divisor != 0, "Division by zero");

    return vec3(_floorDiv(x(a), divisor), _floorDiv(y(a), divisor), _floorDiv(z(a), divisor));
  }

  function neg(Vec3 a) internal pure returns (Vec3) {
    return vec3(-x(a), -y(a), -z(a));
  }

  function manhattanDistance(Vec3 a, Vec3 b) internal pure returns (uint256) {
    return x(a).dist(x(b)) + y(a).dist(y(b)) + z(a).dist(z(b));
  }

  function chebyshevDistance(Vec3 a, Vec3 b) internal pure returns (uint256) {
    uint256 dx = x(a).dist(x(b));
    uint256 dy = y(a).dist(y(b));
    uint256 dz = z(a).dist(z(b));

    return FixedPointMathLib.max(FixedPointMathLib.max(dx, dy), dz);
  }

  function clamp(Vec3 self, Vec3 min, Vec3 max) internal pure returns (Vec3) {
    if (self < min) return min;
    if (max < self) return max;
    return self;
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
    for (uint8 i = 0; i < 26; i++) {
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
      // 270 degree rotation around Y axis
      return vec3(-self.z(), self.y(), self.x());
    }

    // Note: before supporting more directions, we need to ensure clients can render it
    revert("Direction not supported for rotation");
  }

  // Check if the coord is adjacent to the cuboid
  function isAdjacentToCuboid(Vec3 self, Vec3 from, Vec3 to) internal pure returns (bool) {
    // X-axis adjacency (left or right face)
    if (
      (self.x() == from.x() - 1 || self.x() == to.x() + 1) && self.y() >= from.y() && self.y() <= to.y()
        && self.z() >= from.z() && self.z() <= to.z()
    ) {
      return true;
    }
    // Y-axis adjacency (bottom or top face)
    if (
      (self.y() == from.y() - 1 || self.y() == to.y() + 1) && self.x() >= from.x() && self.x() <= to.x()
        && self.z() >= from.z() && self.z() <= to.z()
    ) {
      return true;
    }
    // Z-axis adjacency (front or back face)
    if (
      (self.z() == from.z() - 1 || self.z() == to.z() + 1) && self.x() >= from.x() && self.x() <= to.x()
        && self.y() >= from.y() && self.y() <= to.y()
    ) {
      return true;
    }
    return false;
  }

  function inSurroundingCube(Vec3 self, Vec3 other, uint256 radius) internal pure returns (bool) {
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

  function toForceFieldFragmentCoord(Vec3 coord) internal pure returns (Vec3) {
    return coord.floorDiv(FRAGMENT_SIZE);
  }

  // Note: Local Energy Pool shards are 2D for now, but the table supports 3D
  // Thats why the Y is ignored, and 0 in the util functions
  function toLocalEnergyPoolShardCoord(Vec3 coord) internal pure returns (Vec3) {
    return vec3(_floorDiv(coord.x(), REGION_SIZE), int32(0), _floorDiv(coord.z(), REGION_SIZE));
  }

  function toString(Vec3 a) internal pure returns (string memory) {
    return string(abi.encodePacked("(", x(a).toString(), ",", y(a).toString(), ",", z(a).toString(), ")"));
  }
}

using Vec3Lib for Vec3 global;
using { eq as ==, neq as !=, add as +, sub as -, leq as <=, lt as < } for Vec3 global;

// ======== Helper Functions ========

// Floor division (integer division that rounds down)
function _floorDiv(int32 a, int32 b) pure returns (int32) {
  require(b != 0, "Division by zero");

  // Handle special case for negative numbers
  if ((a < 0) != (b < 0) && a % b != 0) {
    return a / b - 1;
  }

  return a / b;
}

// The `%` operator in Solidity is not a modulo operator, it's a remainder operator, which behaves differently for negative numbers.
function _mod(int32 x, int32 y) pure returns (int32) {
  return ((x % y) + y) % y;
}
