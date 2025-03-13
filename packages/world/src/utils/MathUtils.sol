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

// TODO: we should import math utils from solady or OZ
function min(int256 x, int256 y) pure returns (int256) {
  return x > y ? y : x;
}

function max(int256 x, int256 y) pure returns (int256) {
  return x < y ? y : x;
}

/**
 * @dev Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
 * denominator == 0.
 *
 * TODO: import from OZ or solady?
 *
 * From OpenZeppelin contracts.
 *
 * Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
 * Uniswap Labs also under MIT license.
 */
function mulDiv(uint256 x, uint256 y, uint256 denominator) pure returns (uint256 result) {
  unchecked {
    // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2²⁵⁶ and mod 2²⁵⁶ - 1, then use
    // the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
    // variables such that product = prod1 * 2²⁵⁶ + prod0.
    uint256 prod0 = x * y; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product
    assembly {
      let mm := mulmod(x, y, not(0))
      prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Handle non-overflow cases, 256 by 256 division.
    if (prod1 == 0) {
      // Solidity will revert if denominator == 0, unlike the div opcode on its own.
      // The surrounding unchecked block does not change this fact.
      // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
      return prod0 / denominator;
    }

    // Make sure the result is less than 2²⁵⁶. Also prevents denominator == 0.
    require(denominator > prod1, "mulDiv overflow");

    ///////////////////////////////////////////////
    // 512 by 256 division.
    ///////////////////////////////////////////////

    // Make division exact by subtracting the remainder from [prod1 prod0].
    uint256 remainder;
    assembly {
      // Compute remainder using mulmod.
      remainder := mulmod(x, y, denominator)

      // Subtract 256 bit number from 512 bit number.
      prod1 := sub(prod1, gt(remainder, prod0))
      prod0 := sub(prod0, remainder)
    }

    // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
    // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

    uint256 twos = denominator & (0 - denominator);
    assembly {
      // Divide denominator by twos.
      denominator := div(denominator, twos)

      // Divide [prod1 prod0] by twos.
      prod0 := div(prod0, twos)

      // Flip twos such that it is 2²⁵⁶ / twos. If twos is zero, then it becomes one.
      twos := add(div(sub(0, twos), twos), 1)
    }

    // Shift in bits from prod1 into prod0.
    prod0 |= prod1 * twos;

    // Invert denominator mod 2²⁵⁶. Now that denominator is an odd number, it has an inverse modulo 2²⁵⁶ such
    // that denominator * inv ≡ 1 mod 2²⁵⁶. Compute the inverse by starting with a seed that is correct for
    // four bits. That is, denominator * inv ≡ 1 mod 2⁴.
    uint256 inverse = (3 * denominator) ^ 2;

    // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
    // works in modular arithmetic, doubling the correct bits in each step.
    inverse *= 2 - denominator * inverse; // inverse mod 2⁸
    inverse *= 2 - denominator * inverse; // inverse mod 2¹⁶
    inverse *= 2 - denominator * inverse; // inverse mod 2³²
    inverse *= 2 - denominator * inverse; // inverse mod 2⁶⁴
    inverse *= 2 - denominator * inverse; // inverse mod 2¹²⁸
    inverse *= 2 - denominator * inverse; // inverse mod 2²⁵⁶

    // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
    // This will give us the correct result modulo 2²⁵⁶. Since the preconditions guarantee that the outcome is
    // less than 2²⁵⁶, this is the final result. We don't need to compute the high bits of the result and prod1
    // is no longer required.
    result = prod0 * inverse;
    return result;
  }
}
