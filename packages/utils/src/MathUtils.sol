// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

function absInt16(int16 a) pure returns (int16) {
  return a < 0 ? -a : a;
}

// Divide with rounding down like Math.floor(a/b), not rounding towards zero
function floorDiv(int16 a, int16 b) pure returns (int16) {
  require(b != 0, "Division by zero");
  int16 result = a / b;
  int16 floor = (a < 0 || b < 0) && !(a < 0 && b < 0) && (a % b != 0) ? int16(1) : int16(0);
  return result - floor;
}
