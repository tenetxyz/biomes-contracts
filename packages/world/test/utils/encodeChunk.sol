// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { CHUNK_SIZE } from "../../src/Constants.sol";
import { VERSION_PADDING, BIOME_PADDING, SURFACE_PADDING } from "../../src/systems/libraries/TerrainLib.sol";

function encodeChunk(uint8 biome, bool isSurface, uint8[][][] memory chunk) pure returns (bytes memory encodedChunk) {
  bytes1 version = bytes1(uint8(0));
  encodedChunk = new bytes(uint256(int256(CHUNK_SIZE)) ** 3 + VERSION_PADDING + BIOME_PADDING + SURFACE_PADDING);
  encodedChunk[0] = version;
  encodedChunk[1] = bytes1(biome);
  encodedChunk[2] = bytes1(isSurface ? 1 : 0);
  for (uint256 x = 0; x < uint256(int256(CHUNK_SIZE)); x++) {
    for (uint256 y = 0; y < uint256(int256(CHUNK_SIZE)); y++) {
      for (uint256 z = 0; z < uint256(int256(CHUNK_SIZE)); z++) {
        encodedChunk[
          VERSION_PADDING +
            BIOME_PADDING +
            SURFACE_PADDING +
            x *
            uint256(int256(CHUNK_SIZE)) ** 2 +
            y *
            uint256(int256(CHUNK_SIZE)) +
            z
        ] = bytes1(uint8(chunk[x][y][z]));
      }
    }
  }
}
