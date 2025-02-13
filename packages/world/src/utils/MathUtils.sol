// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

function absInt32(int32 a) pure returns (int32) {
  return a < 0 ? -a : a;
}

// Divide with rounding down like Math.floor(a/b), not rounding towards zero
function floorDiv(int32 a, int32 b) pure returns (int32) {
  require(b != 0, "Division by zero");
  int32 result = a / b;
  int32 floor = (a < 0 || b < 0) && !(a < 0 && b < 0) && (a % b != 0) ? int32(1) : int32(0);
  return result - floor;
}

// The `%` operator in Solidity is not a modulo operator, it's a remainder operator, which behaves differently for negative numbers.
function mod(int256 x, int256 y) pure returns (uint256) {
  return uint256(((x % y) + y) % y);
}
