// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

// Helper function to get the minimum of two uints
function min(uint a, uint b) pure returns (uint) {
  return a < b ? a : b;
}

// Using Babylonian method
function sqrt(uint x) pure returns (uint y) {
  uint z = (x + 1) / 2;
  y = x;
  while (z < y) {
    y = z;
    z = (x / z + z) / 2;
  }
}

// Helper function to calculate the absolute value of an integer
function abs(int x) pure returns (int) {
  if (x < 0) {
    return -x;
  }
  return x;
}

function absInt32(int32 x) pure returns (int32) {
  if (x < 0) {
    return -x;
  }
  return x;
}

// Divide with rounding down like Math.floor(a/b), not rounding towards zero
function floorDiv(int32 a, int32 b) pure returns (int32) {
  require(b != 0, "Division by zero");
  int32 result = a / b;
  int32 floor = (a < 0 || b < 0) && !(a < 0 && b < 0) && (a % b != 0) ? int32(1) : int32(0);
  return result - floor;
}

function absoluteDifference(uint256 a, uint256 b) pure returns (uint256) {
  if (a > b) {
    return a - b;
  } else {
    return b - a;
  }
}
