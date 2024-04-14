// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { IWorld } from "../codegen/world/IWorld.sol";
import { ABDKMath64x64 as Math } from "@biomesaw/utils/src/libraries/ABDKMath64x64.sol";
import { Perlin } from "@biomesaw/utils/src/libraries/Perlin.sol";

import { SandObjectID, BellflowerObjectID, DandelionObjectID, DaylilyObjectID, RedMushroomObjectID, LilacObjectID, RoseObjectID, AzaleaObjectID, CactusObjectID, AirObjectID, SnowObjectID, BasaltObjectID, ClayBrickObjectID, CottonBlockObjectID, StoneObjectID, EmberstoneObjectID, CobblestoneObjectID, MoonstoneObjectID, GraniteObjectID, QuartziteObjectID, LimestoneObjectID, SunstoneObjectID, GravelObjectID, ClayObjectID, BedrockObjectID, LavaObjectID, DiamondOreObjectID, GoldOreObjectID, CoalOreObjectID, SilverOreObjectID, NeptuniumOreObjectID, GrassObjectID, MuckGrassObjectID, DirtObjectID, MuckDirtObjectID, MossBlockObjectID, CottonBushObjectID, SwitchGrassObjectID, OakLogObjectID, BirchLogObjectID, SakuraLogObjectID, RubberLogObjectID, OakLeafObjectID, BirchLeafObjectID, SakuraLeafObjectID, RubberLeafObjectID } from "../ObjectTypeIds.sol";
import { Biome, STRUCTURE_CHUNK, STRUCTURE_CHUNK_CENTER } from "../Constants.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { floorDiv } from "@biomesaw/utils/src/MathUtils.sol";

struct Tuple {
  int128 x;
  int128 y;
}

struct PerlinTuple {
  int128 humidity;
  int128 heat;
  int128 elev;
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

contract TerrainBlockSystem is System {
  //////////////////////////////////////////////////////////////////////////////////////
  // Biomes
  //////////////////////////////////////////////////////////////////////////////////////

  function getBiomeVector(Biome biome) internal pure returns (PerlinTuple memory) {
    if (biome == Biome.Mountains) return PerlinTuple(_0, _0, _1);
    if (biome == Biome.Mountains2) return PerlinTuple(_1, _0, _1);
    if (biome == Biome.Mountains3) return PerlinTuple(_0, _1, _1);
    if (biome == Biome.Mountains4) return PerlinTuple(_1, _1, _1);
    if (biome == Biome.Swamp) return PerlinTuple(_0, _0, _0);
    if (biome == Biome.Plains) return PerlinTuple(_1, _0, _0);
    if (biome == Biome.Forest) return PerlinTuple(_0, _1, _0);
    if (biome == Biome.Desert) return PerlinTuple(_1, _1, _0);
    revert("unknown biome");
  }

  function getBiome(int32 x, int32 z) internal view returns (int128[8] memory) {
    int128 heat = Perlin.noise2d(x + 222, z + 222, 666, 64);
    int128 humidity = Perlin.noise(z, x, 999, 555, 64);
    int128 elev = Perlin.noise(x, z, 999, 444, 64);

    PerlinTuple memory biomeVector = PerlinTuple(humidity, heat, elev);
    int128[8] memory biome;

    biome[uint256(Biome.Mountains)] = pos(
      Math.mul(Math.sub(_0_917, euclidean(biomeVector, getBiomeVector(Biome.Mountains))), _2)
    );

    biome[uint256(Biome.Mountains2)] = pos(
      Math.mul(Math.sub(_0_917, euclidean(biomeVector, getBiomeVector(Biome.Mountains2))), _2)
    );

    biome[uint256(Biome.Mountains3)] = pos(
      Math.mul(Math.sub(_0_917, euclidean(biomeVector, getBiomeVector(Biome.Mountains3))), _2)
    );

    biome[uint256(Biome.Mountains4)] = pos(
      Math.mul(Math.sub(_0_917, euclidean(biomeVector, getBiomeVector(Biome.Mountains4))), _2)
    );

    biome[uint256(Biome.Swamp)] = pos(
      Math.mul(Math.sub(_0_917, euclidean(biomeVector, getBiomeVector(Biome.Swamp))), _2)
    );

    biome[uint256(Biome.Plains)] = pos(
      Math.mul(Math.sub(_0_917, euclidean(biomeVector, getBiomeVector(Biome.Plains))), _2)
    );

    biome[uint256(Biome.Forest)] = pos(
      Math.mul(Math.sub(_0_917, euclidean(biomeVector, getBiomeVector(Biome.Forest))), _2)
    );

    biome[uint256(Biome.Desert)] = pos(
      Math.mul(Math.sub(_0_917, euclidean(biomeVector, getBiomeVector(Biome.Desert))), _2)
    );

    return biome;
  }

  //////////////////////////////////////////////////////////////////////////////////////
  // Heights
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

  function mountains(int128 x) internal view returns (int128) {
    Tuple[] memory splines = new Tuple[](4);
    splines[0] = Tuple(_0, _0);
    splines[1] = Tuple(_0_3, _0_4);
    splines[2] = Tuple(_0_6, _2);
    splines[3] = Tuple(_1, _4);
    return applySpline(x, splines);
  }

  function mountains2(int128 x) internal view returns (int128) {
    Tuple[] memory splines = new Tuple[](4);
    splines[0] = Tuple(_0, _0);
    splines[1] = Tuple(_0_3, _0_3);
    splines[2] = Tuple(_0_6, _1_5);
    splines[3] = Tuple(_1, _3);
    return applySpline(x, splines);
  }

  function mountains3(int128 x) internal view returns (int128) {
    Tuple[] memory splines = new Tuple[](4);
    splines[0] = Tuple(_0, _0);
    splines[1] = Tuple(_0_3, _0_2);
    splines[2] = Tuple(_0_6, _1);
    splines[3] = Tuple(_1, _2);
    return applySpline(x, splines);
  }

  function mountains4(int128 x) internal view returns (int128) {
    Tuple[] memory splines = new Tuple[](4);
    splines[0] = Tuple(_0, _0);
    splines[1] = Tuple(_0_3, _0_1);
    splines[2] = Tuple(_0_6, _0_5);
    splines[3] = Tuple(_1, _1);
    return applySpline(x, splines);
  }

  function flat(int128 x) internal view returns (int128) {
    Tuple[] memory splines = new Tuple[](2);
    splines[0] = Tuple(_0, _0);
    splines[1] = Tuple(_1, _0);
    return applySpline(x, splines);
  }

  function flat2(int128 x) internal view returns (int128) {
    Tuple[] memory splines = new Tuple[](2);
    splines[0] = Tuple(_0, _0);
    splines[1] = Tuple(_1, _0_1);
    return applySpline(x, splines);
  }

  function flat3(int128 x) internal view returns (int128) {
    Tuple[] memory splines = new Tuple[](2);
    splines[0] = Tuple(_0, _0);
    splines[1] = Tuple(_1, _0_2);
    return applySpline(x, splines);
  }

  function flat4(int128 x) internal view returns (int128) {
    Tuple[] memory splines = new Tuple[](2);
    splines[0] = Tuple(_0, _0);
    splines[1] = Tuple(_1, _0_3);
    return applySpline(x, splines);
  }

  function getHeight(int32 x, int32 z) internal view returns (int32) {
    // Compute perlin height
    int128 perlin999 = Perlin.noise2d(x - 550, z + 550, 999, 64);
    int128 terrainHeight = Math.mul(perlin999, _10);
    int128 perlin49 = Perlin.noise2d(x, z, 49, 64);
    terrainHeight = Math.add(terrainHeight, Math.mul(perlin49, _5));
    terrainHeight = Math.add(terrainHeight, Perlin.noise2d(x, z, 13, 64));
    terrainHeight = Math.div(terrainHeight, _16);

    int128[8] memory biome = getBiome(x, z);

    // Compute biome height
    int128 height = Math.mul(biome[uint256(Biome.Mountains)], mountains(terrainHeight));
    height = Math.add(height, Math.mul(biome[uint256(Biome.Mountains2)], mountains2(terrainHeight)));
    height = Math.add(height, Math.mul(biome[uint256(Biome.Mountains3)], mountains3(terrainHeight)));
    height = Math.add(height, Math.mul(biome[uint256(Biome.Mountains4)], mountains4(terrainHeight)));
    height = Math.add(height, Math.mul(biome[uint256(Biome.Swamp)], flat(terrainHeight)));
    height = Math.add(height, Math.mul(biome[uint256(Biome.Desert)], flat2(terrainHeight)));
    height = Math.add(height, Math.mul(biome[uint256(Biome.Plains)], flat3(terrainHeight)));
    height = Math.add(height, Math.mul(biome[uint256(Biome.Forest)], flat4(terrainHeight)));

    height = Math.div(
      height,
      Math.add(
        Math.add(
          Math.add(
            Math.add(
              Math.add(Math.add(Math.add(Math.add(biome[0], biome[1]), biome[2]), biome[3]), biome[4]),
              biome[5]
            ),
            biome[6]
          ),
          biome[7]
        ),
        _1
      )
    );

    // Scale height
    return int32(Math.muli(height, 256) - 70);
  }

  //////////////////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////////////////

  function euclidean(PerlinTuple memory a, PerlinTuple memory b) internal pure returns (int128) {
    int128 dx = Math.sub(a.humidity, b.humidity);
    int128 dy = Math.sub(a.heat, b.heat);
    int128 dz = Math.sub(a.elev, b.elev); // Difference in the z dimension
    return Math.sqrt(Math.add(Math.add(Math.pow(dx, 2), Math.pow(dy, 2)), Math.pow(dz, 2)));
  }

  function pos(int128 x) internal pure returns (int128) {
    return x < 0 ? int128(0) : x;
  }

  function coordEq(VoxelCoord memory a, uint8[3] memory b) internal pure returns (bool) {
    return a.x == int32(uint32(b[0])) && a.y == int32(uint32(b[1])) && a.z == int32(uint32(b[2]));
  }

  function getChunkHash(int32 x, int32 z) internal view returns (uint16) {
    (int32 chunkX, int32 chunkZ) = getChunkCoord(x, z);
    return getCoordHash(chunkX, chunkZ);
  }

  function getChunkHash2(int32 x, int32 z) internal view returns (uint16) {
    (int32 chunkX, int32 chunkZ) = getChunkCoord(x, z);
    return getCoordHash(chunkX + 50, chunkZ + 50);
  }

  function getBiomeHash(int32 x, int32 y, uint8 biome) internal pure returns (uint16) {
    return getCoordHash(floorDiv(x, 300) + floorDiv(y, 300), int32(uint32(biome)));
  }

  function getChunkOffsetAndHeight(
    int32 x,
    int32 y,
    int32 z
  ) internal view returns (int32 height, VoxelCoord memory offset) {
    (int32 chunkX, int32 chunkZ) = getChunkCoord(x, z);
    int32 chunkCenterX = chunkX * STRUCTURE_CHUNK + STRUCTURE_CHUNK_CENTER;
    int32 chunkCenterZ = chunkZ * STRUCTURE_CHUNK + STRUCTURE_CHUNK_CENTER;
    int128[8] memory biome = getBiome(chunkCenterX, chunkCenterZ);
    height = getHeight(chunkCenterX, chunkCenterZ);
    offset = VoxelCoord(x - chunkX * STRUCTURE_CHUNK, y - height, z - chunkZ * STRUCTURE_CHUNK);
  }

  function getCoordHash(int32 x, int32 z) internal pure returns (uint16) {
    uint256 hash = uint256(keccak256(abi.encode(x, z)));
    return uint16(hash % 1024);
  }

  function getChunkCoord(int32 x, int32 z) internal pure returns (int32, int32) {
    return (floorDiv(x, STRUCTURE_CHUNK), floorDiv(z, STRUCTURE_CHUNK));
  }

  function getMaxBiome(int128[8] memory biomeValues) internal pure returns (uint8 biome) {
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

  function OakTree(VoxelCoord memory offset) internal view returns (bytes32) {
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

    return bytes32(0);
  }

  function BirchTree(VoxelCoord memory offset) internal view returns (bytes32) {
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

    return bytes32(0);
  }

  function SakuraTree(VoxelCoord memory offset) internal view returns (bytes32) {
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

    return bytes32(0);
  }

  function RubberTree(VoxelCoord memory offset) internal view returns (bytes32) {
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

    return bytes32(0);
  }

  //////////////////////////////////////////////////////////////////////////////////////
  // Occurences
  //////////////////////////////////////////////////////////////////////////////////////

  function Air(VoxelCoord memory coord) public view returns (bytes32) {
    int128[8] memory biomeValues = getBiome(coord.x, coord.z);
    int32 height = getHeight(coord.x, coord.z);
    // if (coord.y < height) return bytes32(0);

    uint8 biome = getMaxBiome(biomeValues);
    int32 distanceFromHeight = height - coord.y;

    if (Trees(coord.x, coord.y, coord.z, height, biome, distanceFromHeight) != bytes32(0)) return bytes32(0);
    if (Flora(coord.x, coord.y, coord.z, height, biome) != bytes32(0)) return bytes32(0);

    return Air(coord.y, height);
  }

  function Air(int32 y, int32 height) internal pure returns (bytes32) {
    if (y < height) return bytes32(0);

    return AirObjectID;
  }

  function Trees(VoxelCoord memory coord) public view returns (bytes32) {
    int128[8] memory biomeValues = getBiome(coord.x, coord.z);
    int32 height = getHeight(coord.x, coord.z);

    uint8 biome = getMaxBiome(biomeValues);
    int32 distanceFromHeight = height - coord.y;

    return Trees(coord.x, coord.y, coord.z, height, biome, distanceFromHeight);
  }

  function Trees(
    int32 x,
    int32 y,
    int32 z,
    int32 height,
    uint8 biome,
    int32 distanceFromHeight
  ) internal view returns (bytes32) {
    if (y < height) return bytes32(0);

    (int32 chunkHeight, VoxelCoord memory chunkOffset) = getChunkOffsetAndHeight(x, y, z);
    uint16 hash = getChunkHash(x, z);
    bytes32 structObjectTypeId = bytes32(0);

    if (biome == uint8(Biome.Swamp)) {
      if (hash >= 80) return bytes32(0);
      structObjectTypeId = SakuraTree(chunkOffset);
    } else if (biome == uint8(Biome.Plains)) {
      if (hash >= 20) return bytes32(0);
      structObjectTypeId = OakTree(chunkOffset);
    } else if (biome == uint8(Biome.Forest)) {
      if (hash >= 800) return bytes32(0);
      if (hash < 200) {
        structObjectTypeId = RubberTree(chunkOffset);
      } else if (hash >= 200 && hash < 400) {
        structObjectTypeId = BirchTree(chunkOffset);
      } else {
        structObjectTypeId = OakTree(chunkOffset);
      }
    }

    return structObjectTypeId;
  }

  function Flora(VoxelCoord memory coord) public view returns (bytes32) {
    int128[8] memory biomeValues = getBiome(coord.x, coord.z);
    int32 height = getHeight(coord.x, coord.z);

    uint8 biome = getMaxBiome(biomeValues);

    return Flora(coord.x, coord.y, coord.z, height, biome);
  }

  function Flora(int32 x, int32 y, int32 z, int32 height, uint8 biome) internal view returns (bytes32) {
    if (y != height) return bytes32(0);

    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getChunkHash2(x, z);

    if (biome == uint8(Biome.Swamp)) {
      if (hash2 >= 40) return bytes32(0);
      return CottonBushObjectID;
    } else if (biome == uint8(Biome.Desert)) {
      if (hash1 < 8) {
        return CactusObjectID;
      }
    } else if (biome == uint8(Biome.Plains)) {
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
    }

    return bytes32(0);
  }

  function TerrainBlocks(VoxelCoord memory coord) public view returns (bytes32) {
    int128[8] memory biomeValues = getBiome(coord.x, coord.z);
    int32 height = getHeight(coord.x, coord.z);

    uint8 biome = getMaxBiome(biomeValues);
    int32 distanceFromHeight = height - coord.y;

    return TerrainBlocks(coord.x, coord.y, coord.z, height, biome, distanceFromHeight);
  }

  function TerrainBlocks(
    int32 x,
    int32 y,
    int32 z,
    int32 height,
    uint8 biome,
    int32 distanceFromHeight
  ) internal view returns (bytes32) {
    if (y >= height) return bytes32(0);

    if (y < -120) return BedrockObjectID;

    if (distanceFromHeight <= 3) {
      if (distanceFromHeight == 1) {
        if (biome == uint8(Biome.Plains)) return GrassObjectID;
        else if (biome == uint8(Biome.Swamp)) return MuckGrassObjectID;
      }
      if (biome == uint8(Biome.Mountains)) return BasaltObjectID;
      else if (biome == uint8(Biome.Mountains2)) return LimestoneObjectID;
      else if (biome == uint8(Biome.Mountains3)) return QuartziteObjectID;
      else if (biome == uint8(Biome.Mountains4)) return GraniteObjectID;
      else if (biome == uint8(Biome.Forest)) return MossBlockObjectID;
      else if (biome == uint8(Biome.Desert)) return SandObjectID;
    }

    if (
      biome == uint8(Biome.Mountains) ||
      biome == uint8(Biome.Mountains2) ||
      biome == uint8(Biome.Mountains3) ||
      biome == uint8(Biome.Mountains4)
    ) {
      return StoneObjectID;
    } else if (biome == uint8(Biome.Forest) || biome == uint8(Biome.Plains)) {
      return DirtObjectID;
    } else if (biome == uint8(Biome.Swamp)) {
      return MuckDirtObjectID;
    } else if (biome == uint8(Biome.Desert)) {
      return GravelObjectID;
    }

    return bytes32(0);
  }
}
