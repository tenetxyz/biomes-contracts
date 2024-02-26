// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

function uint256ToInt256(uint256 x) pure returns (int256) {
  require(x <= uint256(int256(type(int256).max)), "uint out of bounds");
  return int256(x);
}

function int256ToUint256(int256 x) pure returns (uint256) {
  if (x >= 0) {
    return uint256(x);
  } else {
    return negativeInt256ToUint256(x);
  }
}

function uint256ToInt32(uint256 x) pure returns (int32) {
  require(x <= uint(int(type(int32).max)), "uint out of bounds");
  return int32(int(x));
}

function int32ToUint32(int32 x) pure returns (uint32) {
  require(x >= 0, "int is negative");
  return uint32(uint(int(x)));
}

function uint32ToInt32(uint32 x) pure returns (int32) {
  require(x <= uint32(int32(type(int32).max)), "uint32 out of bounds");
  return int32(x);
}

function uint256ToNegativeInt256(uint256 x) pure returns (int256) {
  require(x <= (uint256(type(int256).max) + 1), "uint out of bounds for negative conversion");
  return -int256(x);
}

function negativeInt256ToUint256(int256 x) pure returns (uint256) {
  require(x < 0, "Value is not negative");
  require(x >= -int256(type(int256).max), "Negative int out of bounds for uint conversion");
  return uint256(-x);
}

function addUint256AndInt256(uint256 a, int256 b) pure returns (uint256) {
  if (b < 0) {
    int256 negativeB = -b; // Make b positive
    require(a >= uint256(negativeB), "Result would be negative");
    return a - uint256(negativeB); // Subtract b from a
  } else {
    return a + int256ToUint256(b); // Add a and b
  }
}

function safeSubtract(uint a, uint b) pure returns (uint) {
  if (a > b) {
    return a - b;
  }
  return 0;
}

function safeAdd(uint a, uint b) pure returns (uint) {
  uint c = a + b;
  require(c >= a, "Addition overflow");
  return c;
}
