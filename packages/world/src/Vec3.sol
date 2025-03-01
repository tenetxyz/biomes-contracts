// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

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

  function squaredMagnitude(Vec3 a) internal pure returns (int64) {
    int64 _x = int64(x(a));
    int64 _y = int64(y(a));
    int64 _z = int64(z(a));
    return _x * _x + _y * _y + _z * _z;
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

  function neighbors6(Vec3 a) internal pure returns (Vec3[6] memory) {
    Vec3[6] memory result;

    // Positive and negative directions along each axis
    result[0] = add(a, vec3(1, 0, 0)); // +x
    result[1] = add(a, vec3(-1, 0, 0)); // -x
    result[2] = add(a, vec3(0, 1, 0)); // +y
    result[3] = add(a, vec3(0, -1, 0)); // -y
    result[4] = add(a, vec3(0, 0, 1)); // +z
    result[5] = add(a, vec3(0, 0, -1)); // -z

    return result;
  }

  function neighbors26(Vec3 a) internal pure returns (Vec3[26] memory) {
    Vec3[26] memory result;
    uint8 idx = 0;

    // Generate all neighbors in a 3x3x3 cube, excluding the center
    for (int32 dx = -1; dx <= 1; dx++) {
      for (int32 dy = -1; dy <= 1; dy++) {
        for (int32 dz = -1; dz <= 1; dz++) {
          if (dx != 0 || dy != 0 || dz != 0) {
            result[idx] = add(a, vec3(dx, dy, dz));
            idx++;
          }
        }
      }
    }

    return result;
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
