// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { IWorld } from "../codegen/world/IWorld.sol";
import { ABDKMath64x64 as Math } from "@biomesaw/utils/src/libraries/ABDKMath64x64.sol";
import { Perlin } from "@biomesaw/utils/src/libraries/Perlin.sol";

import { NullObjectTypeId, WaterObjectID, SandObjectID, BellflowerObjectID, DandelionObjectID, DaylilyObjectID, RedMushroomObjectID, LilacObjectID, RoseObjectID, AzaleaObjectID, CactusObjectID, AirObjectID, SnowObjectID, BasaltObjectID, ClayBrickObjectID, CottonBlockObjectID, StoneObjectID, EmberstoneObjectID, CobblestoneObjectID, MoonstoneObjectID, GraniteObjectID, QuartziteObjectID, LimestoneObjectID, SunstoneObjectID, GravelObjectID, ClayObjectID, BedrockObjectID, DiamondOreObjectID, GoldOreObjectID, CoalOreObjectID, SilverOreObjectID, NeptuniumOreObjectID, GrassObjectID, MuckGrassObjectID, DirtObjectID, MuckDirtObjectID, MossBlockObjectID, CottonBushObjectID, SwitchGrassObjectID, OakLogObjectID, BirchLogObjectID, SakuraLogObjectID, RubberLogObjectID, OakLeafObjectID, BirchLeafObjectID, SakuraLeafObjectID, RubberLeafObjectID } from "../ObjectTypeIds.sol";
import { Biome, STRUCTURE_CHUNK, STRUCTURE_CHUNK_CENTER } from "../Constants.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { floorDiv } from "@biomesaw/utils/src/MathUtils.sol";

struct Tuple {
  int128 x;
  int128 y;
}

int128 constant _0 = 0; // 0 * 2**64
int128 constant _0_1 = 1844674407370955264; // 0.1 * 2**64
int128 constant _0_2 = 3689348814741910323; // 0.2 * 2**64
int128 constant _0_3 = 5534023222112865484; // 0.3 * 2**64
int128 constant _0_4 = 7378697629483820646; // 0.4 * 2**64
int128 constant _0_45 = 8301034833169298227; // 0.45 * 2**64
int128 constant _0_49 = 9038904596117680291; // 0.49 * 2**64
int128 constant _0_499 = 9204925292781066256; // 0.499 * 2**64
int128 constant _0_501 = 9241818780928485359; // 0.501 * 2**64
int128 constant _0_5 = 9223372036854775808; // 0.5 * 2**64
int128 constant _0_51 = 9407839477591871324; // 0.51 * 2**64
int128 constant _0_55 = 10145709240540253388; // 0.55 * 2**64
int128 constant _0_6 = 11068046444225730969; // 0.6 * 2**64
int128 constant _0_75 = 13835058055282163712; // 0.75 * 2**64
int128 constant _0_917 = 16915664315591658831; // 0.917 * 2**64
int128 constant _0_8 = 14757395258967641292; // 0.8 * 2**64
int128 constant _0_9 = 16602069666338596454; // 0.9 * 2**64
int128 constant _1 = 2 ** 64;
int128 constant _1_5 = 27670116110564327424;
int128 constant _2 = 2 * 2 ** 64;
int128 constant _3 = 3 * 2 ** 64;
int128 constant _4 = 4 * 2 ** 64;
int128 constant _5 = 5 * 2 ** 64;
int128 constant _10 = 10 * 2 ** 64;
int128 constant _16 = 16 * 2 ** 64;

contract ProcGenSystem is System {
  //////////////////////////////////////////////////////////////////////////////////////
  // Biomes
  //////////////////////////////////////////////////////////////////////////////////////

  function getBiomeVector(Biome biome) internal pure returns (Tuple memory) {
    if (biome == Biome.Mountains) return Tuple(_0, _0);
    if (biome == Biome.Desert) return Tuple(_0, _1);
    if (biome == Biome.Forest) return Tuple(_1, _0);
    if (biome == Biome.Savanna) return Tuple(_1, _1);
    revert("unknown biome");
  }

  function getBiome(int16 x, int16 z) internal view returns (int128[4] memory) {
    int128 heat = Perlin.noise2d(x + 222, z + 222, 444, 64);
    int128 humidity = Perlin.noise(z, x, 999, 333, 64);

    Tuple memory biomeVector = Tuple(humidity, heat);
    int128[4] memory biome;

    biome[uint256(Biome.Mountains)] = pos(
      Math.mul(Math.sub(_0_75, euclidean(biomeVector, getBiomeVector(Biome.Mountains))), _2)
    );

    biome[uint256(Biome.Desert)] = pos(
      Math.mul(Math.sub(_0_75, euclidean(biomeVector, getBiomeVector(Biome.Desert))), _2)
    );

    biome[uint256(Biome.Forest)] = pos(
      Math.mul(Math.sub(_0_75, euclidean(biomeVector, getBiomeVector(Biome.Forest))), _2)
    );

    biome[uint256(Biome.Savanna)] = pos(
      Math.mul(Math.sub(_0_75, euclidean(biomeVector, getBiomeVector(Biome.Savanna))), _2)
    );

    return biome;
  }

  //////////////////////////////////////////////////////////////////////////////////////
  // Spline functions
  //////////////////////////////////////////////////////////////////////////////////////

  function applySpline(int128 x, Tuple[] memory splines) internal view returns (int128) {
    Tuple[2] memory points;

    // Find spline points
    if (splines.length == 2) {
      points = [splines[0], splines[1]];
    } else {
      for (uint256 index; index < splines.length; index++) {
        if (splines[index].x >= x) {
          points = [splines[index - 1], splines[index]];
          break;
        }
      }
    }

    int128 t = Math.div(Math.sub(x, points[0].x), Math.sub(points[1].x, points[0].x));
    return Perlin.lerp(t, points[0].y, points[1].y);
  }

  function continentalness(int128 x) internal view returns (int128) {
    Tuple[] memory splines = new Tuple[](3);
    splines[0] = Tuple(_0, _0_4);
    splines[1] = Tuple(_0_5, _0_6);
    splines[2] = Tuple(_1, _0_9);
    return applySpline(x, splines);
  }

  function mountains(int128 x) internal view returns (int128) {
    Tuple[] memory splines = new Tuple[](4);
    splines[0] = Tuple(_0, _0);
    splines[1] = Tuple(_0_3, _0_4);
    splines[2] = Tuple(_0_6, _2);
    splines[3] = Tuple(_1, _4);
    return applySpline(x, splines);
  }

  function desert(int128 x) internal view returns (int128) {
    Tuple[] memory splines = new Tuple[](2);
    splines[0] = Tuple(_0, _0);
    splines[1] = Tuple(_1, _0_4);
    return applySpline(x, splines);
  }

  function forest(int128 x) internal view returns (int128) {
    Tuple[] memory splines = new Tuple[](2);
    splines[0] = Tuple(_0, _0);
    splines[1] = Tuple(_1, _0_5);
    return applySpline(x, splines);
  }

  function savanna(int128 x) internal view returns (int128) {
    Tuple[] memory splines = new Tuple[](2);
    splines[0] = Tuple(_0, _0);
    splines[1] = Tuple(_1, _0_4);
    return applySpline(x, splines);
  }

  function valleys(int128 x) internal view returns (int128) {
    Tuple[] memory splines = new Tuple[](8);
    splines[0] = Tuple(_0, _1);
    splines[1] = Tuple(_0_45, _1);
    splines[2] = Tuple(_0_49, _0_9);
    splines[3] = Tuple(_0_499, _0_8);
    splines[4] = Tuple(_0_501, _0_8);
    splines[5] = Tuple(_0_51, _0_9);
    splines[6] = Tuple(_0_55, _1);
    splines[7] = Tuple(_1, _1);
    return applySpline(x, splines);
  }

  function getHeight(int16 x, int16 z, int128[4] memory biome) internal view returns (int16) {
    // Compute perlin height
    int128 perlin999 = Perlin.noise2d(x - 550, z + 550, 999, 64);
    int128 continentalHeight = continentalness(perlin999);
    int128 terrainHeight = Math.mul(perlin999, _10);
    int128 perlin49 = Perlin.noise2d(x, z, 49, 64);
    terrainHeight = Math.add(terrainHeight, Math.mul(perlin49, _5));
    terrainHeight = Math.add(terrainHeight, Perlin.noise2d(x, z, 13, 64));
    terrainHeight = Math.div(terrainHeight, _16);

    // Compute biome height
    int128 height = Math.mul(biome[uint256(Biome.Mountains)], mountains(terrainHeight));
    height = Math.add(height, Math.mul(biome[uint256(Biome.Desert)], desert(terrainHeight)));
    height = Math.add(height, Math.mul(biome[uint256(Biome.Forest)], forest(terrainHeight)));
    height = Math.add(height, Math.mul(biome[uint256(Biome.Savanna)], savanna(terrainHeight)));
    height = Math.div(height, Math.add(Math.add(Math.add(Math.add(biome[0], biome[1]), biome[2]), biome[3]), _1));

    height = Math.add(continentalHeight, Math.div(height, _2));

    // Create valleys
    if (biome[uint256(Biome.Mountains)] > 0 || biome[uint256(Biome.Forest)] > 0) {
      int128 valley = valleys(Math.div(Math.add(Math.mul(Perlin.noise2d(x, z, 333, 64), _2), perlin49), _3));
      height = Math.mul(height, valley);
    }

    // Scale height
    return int16(Math.muli(height, 256) - 128);
  }

  //////////////////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////////////////

  function euclidean(Tuple memory a, Tuple memory b) internal pure returns (int128) {
    return Math.sqrt(Math.add(Math.pow(Math.sub(a.x, b.x), 2), Math.pow(Math.sub(a.y, b.y), 2)));
  }

  function pos(int128 x) internal pure returns (int128) {
    return x < 0 ? int128(0) : x;
  }

  function coordEq(VoxelCoord memory a, uint8[3] memory b) internal pure returns (bool) {
    return a.x == int16(uint16(b[0])) && a.y == int16(uint16(b[1])) && a.z == int16(uint16(b[2]));
  }

  function getChunkHash(int16 x, int16 z) internal view returns (uint16) {
    (int16 chunkX, int16 chunkZ) = getChunkCoord(x, z);
    return getCoordHash(chunkX, chunkZ);
  }

  function getChunkHash2(int16 x, int16 z) internal view returns (uint16) {
    (int16 chunkX, int16 chunkZ) = getChunkCoord(x, z);
    return getCoordHash(chunkX + 50, chunkZ + 50);
  }

  function getBiomeHash(int16 x, int16 y, uint8 biome) internal pure returns (uint16) {
    return getCoordHash(floorDiv(x, 300) + floorDiv(y, 300), int16(uint16(biome)));
  }

  function getChunkOffsetAndHeight(
    int16 x,
    int16 y,
    int16 z
  ) internal view returns (int16 height, VoxelCoord memory offset) {
    (int16 chunkX, int16 chunkZ) = getChunkCoord(x, z);
    int16 chunkCenterX = chunkX * STRUCTURE_CHUNK + STRUCTURE_CHUNK_CENTER;
    int16 chunkCenterZ = chunkZ * STRUCTURE_CHUNK + STRUCTURE_CHUNK_CENTER;
    int128[4] memory biome = getBiome(chunkCenterX, chunkCenterZ);
    height = getHeight(chunkCenterX, chunkCenterZ, biome);
    offset = VoxelCoord(x - chunkX * STRUCTURE_CHUNK, y - height, z - chunkZ * STRUCTURE_CHUNK);
  }

  function getCoordHash(int16 x, int16 z) internal pure returns (uint16) {
    uint256 hash = uint256(keccak256(abi.encode(x, z)));
    return uint16(hash % 1024);
  }

  function getChunkCoord(int16 x, int16 z) internal pure returns (int16, int16) {
    return (floorDiv(x, STRUCTURE_CHUNK), floorDiv(z, STRUCTURE_CHUNK));
  }

  function getMaxBiome(int128[4] memory biomeValues) internal pure returns (uint8 biome) {
    int128 maxBiome;
    for (uint256 i; i < biomeValues.length; i++) {
      if (biomeValues[i] > maxBiome) {
        maxBiome = biomeValues[i];
        biome = uint8(i);
      }
    }
  }

  //////////////////////////////////////////////////////////////////////////////////////
  // Structures
  //////////////////////////////////////////////////////////////////////////////////////

  function OakTree(VoxelCoord memory offset) internal view returns (uint8) {
    // Trunk
    if (coordEq(offset, [3, 0, 3])) return OakLogObjectID;
    if (coordEq(offset, [3, 1, 3])) return OakLogObjectID;
    if (coordEq(offset, [3, 2, 3])) return OakLogObjectID;
    if (coordEq(offset, [3, 3, 3])) return OakLogObjectID;

    // Leaves
    if (coordEq(offset, [2, 3, 3])) return OakLeafObjectID;
    if (coordEq(offset, [3, 3, 2])) return OakLeafObjectID;
    if (coordEq(offset, [4, 3, 3])) return OakLeafObjectID;
    if (coordEq(offset, [3, 3, 4])) return OakLeafObjectID;
    if (coordEq(offset, [2, 3, 2])) return OakLeafObjectID;
    if (coordEq(offset, [4, 3, 4])) return OakLeafObjectID;
    if (coordEq(offset, [2, 3, 4])) return OakLeafObjectID;
    if (coordEq(offset, [4, 3, 2])) return OakLeafObjectID;
    if (coordEq(offset, [2, 4, 3])) return OakLeafObjectID;
    if (coordEq(offset, [3, 4, 2])) return OakLeafObjectID;
    if (coordEq(offset, [4, 4, 3])) return OakLeafObjectID;
    if (coordEq(offset, [3, 4, 4])) return OakLeafObjectID;
    if (coordEq(offset, [3, 4, 3])) return OakLeafObjectID;

    return NullObjectTypeId;
  }

  function BirchTree(VoxelCoord memory offset) internal view returns (uint8) {
    // Trunk
    if (coordEq(offset, [3, 0, 3])) return BirchLogObjectID;
    if (coordEq(offset, [3, 1, 3])) return BirchLogObjectID;
    if (coordEq(offset, [3, 2, 3])) return BirchLogObjectID;
    if (coordEq(offset, [3, 3, 3])) return BirchLogObjectID;

    // Leaves
    if (coordEq(offset, [2, 3, 3])) return BirchLeafObjectID;
    if (coordEq(offset, [3, 3, 2])) return BirchLeafObjectID;
    if (coordEq(offset, [4, 3, 3])) return BirchLeafObjectID;
    if (coordEq(offset, [3, 3, 4])) return BirchLeafObjectID;
    if (coordEq(offset, [2, 3, 2])) return BirchLeafObjectID;
    if (coordEq(offset, [4, 3, 4])) return BirchLeafObjectID;
    if (coordEq(offset, [2, 3, 4])) return BirchLeafObjectID;
    if (coordEq(offset, [4, 3, 2])) return BirchLeafObjectID;
    if (coordEq(offset, [2, 4, 3])) return BirchLeafObjectID;
    if (coordEq(offset, [3, 4, 2])) return BirchLeafObjectID;
    if (coordEq(offset, [4, 4, 3])) return BirchLeafObjectID;
    if (coordEq(offset, [3, 4, 4])) return BirchLeafObjectID;
    if (coordEq(offset, [3, 4, 3])) return BirchLeafObjectID;

    return NullObjectTypeId;
  }

  function SakuraTree(VoxelCoord memory offset) internal view returns (uint8) {
    // Trunk
    if (coordEq(offset, [3, 0, 3])) return SakuraLogObjectID;
    if (coordEq(offset, [3, 1, 3])) return SakuraLogObjectID;
    if (coordEq(offset, [3, 2, 3])) return SakuraLogObjectID;
    if (coordEq(offset, [3, 3, 3])) return SakuraLogObjectID;

    // Leaves
    if (coordEq(offset, [2, 3, 3])) return SakuraLeafObjectID;
    if (coordEq(offset, [3, 3, 2])) return SakuraLeafObjectID;
    if (coordEq(offset, [4, 3, 3])) return SakuraLeafObjectID;
    if (coordEq(offset, [3, 3, 4])) return SakuraLeafObjectID;
    if (coordEq(offset, [2, 3, 2])) return SakuraLeafObjectID;
    if (coordEq(offset, [4, 3, 4])) return SakuraLeafObjectID;
    if (coordEq(offset, [2, 3, 4])) return SakuraLeafObjectID;
    if (coordEq(offset, [4, 3, 2])) return SakuraLeafObjectID;
    if (coordEq(offset, [2, 4, 3])) return SakuraLeafObjectID;
    if (coordEq(offset, [3, 4, 2])) return SakuraLeafObjectID;
    if (coordEq(offset, [4, 4, 3])) return SakuraLeafObjectID;
    if (coordEq(offset, [3, 4, 4])) return SakuraLeafObjectID;
    if (coordEq(offset, [3, 4, 3])) return SakuraLeafObjectID;

    return NullObjectTypeId;
  }

  function RubberTree(VoxelCoord memory offset) internal view returns (uint8) {
    // Trunk
    if (coordEq(offset, [3, 0, 3])) return RubberLogObjectID;
    if (coordEq(offset, [3, 1, 3])) return RubberLogObjectID;
    if (coordEq(offset, [3, 2, 3])) return RubberLogObjectID;
    if (coordEq(offset, [3, 3, 3])) return RubberLogObjectID;

    // Leaves
    if (coordEq(offset, [2, 3, 3])) return RubberLeafObjectID;
    if (coordEq(offset, [3, 3, 2])) return RubberLeafObjectID;
    if (coordEq(offset, [4, 3, 3])) return RubberLeafObjectID;
    if (coordEq(offset, [3, 3, 4])) return RubberLeafObjectID;
    if (coordEq(offset, [2, 3, 2])) return RubberLeafObjectID;
    if (coordEq(offset, [4, 3, 4])) return RubberLeafObjectID;
    if (coordEq(offset, [2, 3, 4])) return RubberLeafObjectID;
    if (coordEq(offset, [4, 3, 2])) return RubberLeafObjectID;
    if (coordEq(offset, [2, 4, 3])) return RubberLeafObjectID;
    if (coordEq(offset, [3, 4, 2])) return RubberLeafObjectID;
    if (coordEq(offset, [4, 4, 3])) return RubberLeafObjectID;
    if (coordEq(offset, [3, 4, 4])) return RubberLeafObjectID;
    if (coordEq(offset, [3, 4, 3])) return RubberLeafObjectID;

    return NullObjectTypeId;
  }

  function CottonPatch(uint16 hash1, uint16 hash2, VoxelCoord memory offset) internal view returns (uint8) {
    int16 densitySeed = int16((hash1 % 10) + (hash2 % 10));
    if ((offset.x + offset.y + offset.z + densitySeed) % 3 == 0) return CottonBlockObjectID;

    return NullObjectTypeId;
  }

  //////////////////////////////////////////////////////////////////////////////////////
  // Occurences
  //////////////////////////////////////////////////////////////////////////////////////

  function getTerrainBlock(VoxelCoord memory coord) public view returns (uint8) {
    int128[4] memory biomeValues = getBiome(coord.x, coord.z);
    int16 height = getHeight(coord.x, coord.z, biomeValues);
    uint8 biome = getMaxBiome(biomeValues);
    int16 distanceFromHeight = height - coord.y;

    uint8 objectTypeId;

    objectTypeId = Water(coord.y, height);
    if (objectTypeId != NullObjectTypeId) return objectTypeId;

    objectTypeId = Air(coord.y, height);
    if (objectTypeId != NullObjectTypeId) return objectTypeId;

    objectTypeId = Ores(coord.x, coord.y, coord.z, height, biome, distanceFromHeight);
    if (objectTypeId != NullObjectTypeId) return objectTypeId;

    objectTypeId = TerrainBlocks(coord.x, coord.y, coord.z, height, biome, distanceFromHeight);
    if (objectTypeId != NullObjectTypeId) return objectTypeId;

    objectTypeId = Trees(coord.x, coord.y, coord.z, height, biome, distanceFromHeight);
    if (objectTypeId != NullObjectTypeId) return objectTypeId;

    objectTypeId = Flora(coord.x, coord.y, coord.z, height, biome);
    if (objectTypeId != NullObjectTypeId) return objectTypeId;

    return AirObjectID;
  }

  function Air(VoxelCoord memory coord) public view returns (uint8) {
    int128[4] memory biomeValues = getBiome(coord.x, coord.z);
    int16 height = getHeight(coord.x, coord.z, biomeValues);
    return Air(coord.y, height);
  }

  function Air(int16 y, int16 height) internal pure returns (uint8) {
    if (y >= height + 2 * STRUCTURE_CHUNK) return AirObjectID;

    return NullObjectTypeId;
  }

  function Water(VoxelCoord memory coord) public view returns (uint8) {
    int128[4] memory biomeValues = getBiome(coord.x, coord.z);
    int16 height = getHeight(coord.x, coord.z, biomeValues);
    return Water(coord.y, height);
  }

  function Water(int16 y, int16 height) internal pure returns (uint8) {
    if (y < 0 && y >= height) return WaterObjectID;

    return NullObjectTypeId;
  }

  function Ores(VoxelCoord memory coord) public view returns (uint8) {
    int128[4] memory biomeValues = getBiome(coord.x, coord.z);
    int16 height = getHeight(coord.x, coord.z, biomeValues);

    uint8 biome = getMaxBiome(biomeValues);
    int16 distanceFromHeight = height - coord.y;

    return Ores(coord.x, coord.y, coord.z, height, biome, distanceFromHeight);
  }

  function Trees(VoxelCoord memory coord) public view returns (uint8) {
    int128[4] memory biomeValues = getBiome(coord.x, coord.z);
    int16 height = getHeight(coord.x, coord.z, biomeValues);

    uint8 biome = getMaxBiome(biomeValues);
    int16 distanceFromHeight = height - coord.y;

    return Trees(coord.x, coord.y, coord.z, height, biome, distanceFromHeight);
  }

  function Trees(
    int16 x,
    int16 y,
    int16 z,
    int16 height,
    uint8 biome,
    int16 distanceFromHeight
  ) internal view returns (uint8) {
    if (y < height || y < 0) return NullObjectTypeId;

    (int16 chunkHeight, VoxelCoord memory chunkOffset) = getChunkOffsetAndHeight(x, y, z);
    if (chunkHeight <= 0) return NullObjectTypeId;

    uint16 hash = getChunkHash(x, z);
    uint8 structObjectTypeId = NullObjectTypeId;

    if (biome == uint8(Biome.Savanna)) {
      if (hash >= 20) return NullObjectTypeId;
      structObjectTypeId = OakTree(chunkOffset);
    } else if (biome == uint8(Biome.Forest)) {
      if (hash >= 300) return NullObjectTypeId;
      if (hash < 50) {
        structObjectTypeId = SakuraTree(chunkOffset);
      } else if (hash >= 50 && hash < 100) {
        structObjectTypeId = RubberTree(chunkOffset);
      } else if (hash >= 100 && hash < 150) {
        structObjectTypeId = BirchTree(chunkOffset);
      } else {
        structObjectTypeId = OakTree(chunkOffset);
      }
    }

    return structObjectTypeId;
  }

  function Flora(VoxelCoord memory coord) public view returns (uint8) {
    int128[4] memory biomeValues = getBiome(coord.x, coord.z);
    int16 height = getHeight(coord.x, coord.z, biomeValues);

    uint8 biome = getMaxBiome(biomeValues);

    return Flora(coord.x, coord.y, coord.z, height, biome);
  }

  function Flora(int16 x, int16 y, int16 z, int16 height, uint8 biome) internal view returns (uint8) {
    if (y != height || y < 0) return NullObjectTypeId;

    uint16 hash1 = getCoordHash(x, z);

    if (biome == uint8(Biome.Desert)) {
      if (hash1 < 6) {
        return CactusObjectID;
      }
    } else if (biome == uint8(Biome.Savanna)) {
      if (hash1 < 4) {
        return BellflowerObjectID;
      } else if (hash1 >= 4 && hash1 < 8) {
        return DandelionObjectID;
      } else if (hash1 >= 8 && hash1 < 12) {
        return DaylilyObjectID;
      } else if (hash1 >= 12 && hash1 < 16) {
        return RedMushroomObjectID;
      } else if (hash1 >= 16 && hash1 < 20) {
        return LilacObjectID;
      } else if (hash1 >= 20 && hash1 < 24) {
        return RoseObjectID;
      } else if (hash1 >= 24 && hash1 < 28) {
        return AzaleaObjectID;
      }
    } else if (biome == uint8(Biome.Mountains)) {
      (int16 chunkHeight, VoxelCoord memory chunkOffset) = getChunkOffsetAndHeight(x, y, z);
      if (chunkHeight <= 0) return NullObjectTypeId;

      uint16 hash2 = getChunkHash2(x, z);
      if (hash2 < 30) {
        return CottonPatch(hash1, hash2, chunkOffset);
      }
    }

    return NullObjectTypeId;
  }

  function TerrainBlocks(VoxelCoord memory coord) public view returns (uint8) {
    int128[4] memory biomeValues = getBiome(coord.x, coord.z);
    int16 height = getHeight(coord.x, coord.z, biomeValues);

    uint8 biome = getMaxBiome(biomeValues);
    int16 distanceFromHeight = height - coord.y;

    return TerrainBlocks(coord.x, coord.y, coord.z, height, biome, distanceFromHeight);
  }

  function TerrainBlocks(
    int16 x,
    int16 y,
    int16 z,
    int16 height,
    uint8 biome,
    int16 distanceFromHeight
  ) internal view returns (uint8) {
    if (y >= height) return NullObjectTypeId;

    if (y < -120) return BedrockObjectID;

    if (distanceFromHeight <= 5) {
      if (distanceFromHeight == 1 && y > 0) {
        if (biome == uint8(Biome.Savanna)) return GrassObjectID;
      }
      if (biome == uint8(Biome.Mountains)) return StoneObjectID;
      else if (biome == uint8(Biome.Forest) && y > 0) return MossBlockObjectID;
    }

    if (biome == uint8(Biome.Mountains)) {
      if (y <= -50) {
        return BasaltObjectID;
      } else if (y <= 30) {
        return GraniteObjectID;
      } else if (y > 30 && y <= 80) {
        return LimestoneObjectID;
      } else if (y > 80) {
        return QuartziteObjectID;
      }
    } else if (biome == uint8(Biome.Desert)) {
      if (y < 0) {
        return GravelObjectID;
      } else {
        return SandObjectID;
      }
    } else if (biome == uint8(Biome.Forest)) {
      return DirtObjectID;
    } else if (biome == uint8(Biome.Savanna)) {
      return DirtObjectID;
    }

    return NullObjectTypeId;
  }

  function Ores(
    int16 x,
    int16 y,
    int16 z,
    int16 height,
    uint8 biome,
    int16 distanceFromHeight
  ) internal view returns (uint8) {
    if (y >= height) return NullObjectTypeId;

    // Checking biome conditions and distance from height for ore generation
    if (biome == uint8(Biome.Mountains)) {
      if (y > 10 && y <= 40) {
        return oreRegion1Mount(x, y, z);
      } else if (y > 40 && y <= 80) {
        return oreRegion2Mount(x, y, z);
      } else if (y > 80) {
        return oreRegion3Mount(x, y, z);
      }
    } else {
      if (distanceFromHeight >= 5 && distanceFromHeight <= 17) {
        if (biome == uint8(Biome.Desert)) {
          return oreRegion1Desert(x, y, z);
        } else {
          return oreRegion1(x, y, z);
        }
      } else if (distanceFromHeight > 17 && distanceFromHeight <= 40) {
        if (biome == uint8(Biome.Desert)) {
          return oreRegion2Desert(x, y, z);
        } else {
          return oreRegion2(x, y, z);
        }
      } else if (distanceFromHeight > 40) {
        if (biome == uint8(Biome.Desert)) {
          return oreRegion3Desert(x, y, z);
        } else {
          return oreRegion3(x, y, z);
        }
      }
    }

    return NullObjectTypeId;
  }

  function oreRegion1(int16 x, int16 y, int16 z) internal view returns (uint8) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    // REGION 1: Coal is Abundant, Silver is Rare
    if (hash1 <= 20 || hash1 > 40) {
      if (hash1 <= 15 && hash2 <= 15) {
        return SilverOreObjectID;
      }
    } else {
      if (hash2 > 0 && hash2 <= 20) {
        return CoalOreObjectID;
      }
    }
    return NullObjectTypeId;
  }

  function oreRegion1Desert(int16 x, int16 y, int16 z) internal view returns (uint8) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    // REGION 1: Coal is Abundant, Silver is Rare, Boost Gold Lightly
    if (hash1 <= 20 || hash1 > 40) {
      if (hash1 <= 15 && hash2 <= 15) {
        return SilverOreObjectID;
      } else if (hash1 <= 5 && hash2 <= 5) {
        return GoldOreObjectID;
      }
    } else {
      if (hash2 > 0 && hash2 <= 15) {
        return CoalOreObjectID;
      }
    }
    return NullObjectTypeId;
  }

  function oreRegion1Mount(int16 x, int16 y, int16 z) internal view returns (uint8) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    // REGION 1: Coal is Abundant, Silver is Rare But Boosted
    if (hash1 <= 20 || hash1 > 40) {
      if (hash1 <= 20 && hash2 <= 20) {
        return SilverOreObjectID;
      }
    } else {
      if (hash2 > 0 && hash2 <= 20) {
        return CoalOreObjectID;
      }
    }
    return NullObjectTypeId;
  }

  function oreRegion2(int16 x, int16 y, int16 z) internal view returns (uint8) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    // REGION 2: Coal and Silver Equally Abundant, Gold is Rare, Diamond is Even More Rare
    if (hash1 <= 30) {
      if (hash2 > 0 && hash2 <= 20) {
        return CoalOreObjectID;
      }
    } else if (hash1 > 20 && hash1 <= 55) {
      if (hash2 > 10 && hash2 <= 35) {
        return SilverOreObjectID;
      }
    } else if (hash1 > 40 && hash1 <= 65) {
      if (hash2 > 25 && hash2 <= 45) {
        return GoldOreObjectID;
      } else if (hash2 > 35 && hash2 <= 50) {
        return DiamondOreObjectID;
      }
    }
    return NullObjectTypeId;
  }

  function oreRegion2Desert(int16 x, int16 y, int16 z) internal view returns (uint8) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    // REGION 2: Coal and Silver Equally Abundant, Gold is Rare But Boosted, Diamond is Even More Rare
    if (hash1 <= 30) {
      if (hash2 > 0 && hash2 <= 20) {
        return CoalOreObjectID;
      }
    } else if (hash1 > 20 && hash1 <= 55) {
      if (hash2 > 10 && hash2 <= 35) {
        return SilverOreObjectID;
      } else if (hash2 > 25 && hash2 <= 45) {
        return GoldOreObjectID;
      }
    } else if (hash1 > 40 && hash1 <= 65) {
      if (hash2 > 40 && hash2 <= 55) {
        return DiamondOreObjectID;
      }
    }
    return NullObjectTypeId;
  }

  function oreRegion2Mount(int16 x, int16 y, int16 z) internal view returns (uint8) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    // REGION 2: Coal and Silver Equally Abundant, Gold is Rare, Diamond is Even More Rare but Boosted
    if (hash1 <= 20) {
      if (hash2 > 0 && hash2 <= 20) {
        return CoalOreObjectID;
      }
    } else if (hash1 > 20 && hash1 <= 55) {
      if (hash2 > 10 && hash2 <= 35) {
        return SilverOreObjectID;
      }
    } else if (hash1 > 40 && hash1 <= 65) {
      if (hash2 > 25 && hash2 <= 45) {
        return GoldOreObjectID;
      } else if (hash2 > 35 && hash2 <= 60) {
        return DiamondOreObjectID;
      }
    }
    return NullObjectTypeId;
  }

  function oreRegion3(int16 x, int16 y, int16 z) internal view returns (uint8) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    // REGION 3: Coal, Silver, and Gold Equally Abundant, Diamond is Rare, Neptunium is Even More Rare
    if (hash1 <= 30) {
      if (hash2 > 0 && hash2 <= 20) {
        return CoalOreObjectID;
      }
    } else if (hash1 > 20 && hash1 <= 55) {
      if (hash2 > 10 && hash2 <= 35) {
        return SilverOreObjectID;
      }
    } else if (hash1 > 45 && hash1 <= 80) {
      if (hash2 > 25 && hash2 <= 50) {
        return GoldOreObjectID;
      }
    } else if (hash1 > 70 && hash1 <= 95) {
      if (hash2 > 40 && hash2 <= 60) {
        return DiamondOreObjectID;
      } else if (hash2 > 50 && hash2 <= 65) {
        return NeptuniumOreObjectID;
      }
    }
    return NullObjectTypeId;
  }

  function oreRegion3Desert(int16 x, int16 y, int16 z) internal view returns (uint8) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    // REGION 3: Coal, Silver, and Gold Equally Abundant But Boosted Even More, Diamond is Rare, Neptunium is Even More Rare
    if (hash1 <= 30) {
      if (hash2 > 0 && hash2 <= 20) {
        return CoalOreObjectID;
      }
    } else if (hash1 > 20 && hash1 <= 55) {
      if (hash2 > 10 && hash2 <= 35) {
        return SilverOreObjectID;
      }
    } else if (hash1 > 45 && hash1 <= 80) {
      if (hash2 > 25 && hash2 <= 60) {
        return GoldOreObjectID;
      }
    } else if (hash1 > 70 && hash1 <= 95) {
      if (hash2 > 50 && hash2 <= 70) {
        return DiamondOreObjectID;
      } else if (hash2 > 60 && hash2 <= 75) {
        return NeptuniumOreObjectID;
      }
    }
    return NullObjectTypeId;
  }

  function oreRegion3Mount(int16 x, int16 y, int16 z) internal view returns (uint8) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    // REGION 3: Coal, Silver, and Gold Equally Abundant, Diamond is Rare, Neptunium is Even More Rare
    if (hash1 <= 30) {
      if (hash2 > 0 && hash2 <= 20) {
        return CoalOreObjectID;
      }
    } else if (hash1 > 20 && hash1 <= 55) {
      if (hash2 > 10 && hash2 <= 35) {
        return SilverOreObjectID;
      }
    } else if (hash1 > 45 && hash1 <= 80) {
      if (hash2 > 25 && hash2 <= 50) {
        return GoldOreObjectID;
      }
    } else if (hash1 > 70 && hash1 <= 95) {
      if (hash2 > 40 && hash2 <= 60) {
        return DiamondOreObjectID;
      } else if (hash2 > 50 && hash2 <= 75) {
        return NeptuniumOreObjectID;
      }
    }
    return NullObjectTypeId;
  }
}
