// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

// Divide with rounding down like Math.floor(a/b), not rounding towards zero
function floorDiv(int32 a, int32 b) pure returns (int32) {
  require(b != 0, "Division by zero");
  int32 result = a / b;
  int32 floor = (a < 0 || b < 0) && !(a < 0 && b < 0) && (a % b != 0) ? int32(1) : int32(0);
  return result - floor;
}
