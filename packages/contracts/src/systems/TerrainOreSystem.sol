// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { IWorld } from "../codegen/world/IWorld.sol";
import { ABDKMath64x64 as Math } from "@biomesaw/utils/src/libraries/ABDKMath64x64.sol";
import { Perlin } from "@biomesaw/utils/src/libraries/Perlin.sol";

import { SandObjectID, BellflowerObjectID, DandelionObjectID, DaylilyObjectID, RedMushroomObjectID, LilacObjectID, RoseObjectID, AzaleaObjectID, CactusObjectID, AirObjectID, SnowObjectID, AsphaltObjectID, BasaltObjectID, ClayBrickObjectID, CottonBlockObjectID, StoneObjectID, EmberstoneObjectID, CobblestoneObjectID, MoonstoneObjectID, GraniteObjectID, QuartziteObjectID, LimestoneObjectID, SunstoneObjectID, SoilObjectID, GravelObjectID, ClayObjectID, BedrockObjectID, LavaObjectID, DiamondOreObjectID, GoldOreObjectID, CoalOreObjectID, SilverOreObjectID, NeptuniumOreObjectID, GrassObjectID, MuckGrassObjectID, DirtObjectID, MuckDirtObjectID, MossBlockObjectID, CottonBushObjectID, MossGrassObjectID, SwitchGrassObjectID, OakLogObjectID, BirchLogObjectID, SakuraLogObjectID, RubberLogObjectID, OakLeafObjectID, BirchLeafObjectID, SakuraLeafObjectID, RubberLeafObjectID } from "../ObjectTypeIds.sol";
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

contract TerrainOreSystem is System {
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
  // Occurences
  //////////////////////////////////////////////////////////////////////////////////////

  function Ores(VoxelCoord memory coord) public view returns (bytes32) {
    int128[8] memory biomeValues = getBiome(coord.x, coord.z);
    int32 height = getHeight(coord.x, coord.z);

    uint8 biome = getMaxBiome(biomeValues);
    int32 distanceFromHeight = height - coord.y;

    return Ores(coord.x, coord.y, coord.z, height, biome, distanceFromHeight);
  }

  function Ores(
    int32 x,
    int32 y,
    int32 z,
    int32 height,
    uint8 biome,
    int32 distanceFromHeight
  ) internal view returns (bytes32) {
    if (y >= height) return bytes32(0);

    // Checking biome conditions and distance from height for ore generation
    if (
      y < -20 &&
      biome != uint8(Biome.Mountains) &&
      biome != uint8(Biome.Mountains2) &&
      biome != uint8(Biome.Mountains3) &&
      biome != uint8(Biome.Mountains4)
    ) {
      if (distanceFromHeight >= 10 && distanceFromHeight <= 20) {
        if (biome == uint8(Biome.Desert)) {
          return oreRegion1Desert(x, y, z);
        } else {
          return oreRegion1(x, y, z);
        }
      } else if (distanceFromHeight > 20 && distanceFromHeight <= 40) {
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
    } else if (
      biome == uint8(Biome.Mountains) ||
      biome == uint8(Biome.Mountains2) ||
      biome == uint8(Biome.Mountains3) ||
      biome == uint8(Biome.Mountains4)
    ) {
      if (y > -20 && y <= 30) {
        return oreRegion1Mount(x, y, z);
      } else if (y > 30 && y <= 80) {
        return oreRegion2Mount(x, y, z);
      } else if (y > 80) {
        return oreRegion3Mount(x, y, z);
      }
    }
    return bytes32(0);
  }

  function oreRegion1(int32 x, int32 y, int32 z) internal view returns (bytes32) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    // REGION 1: Coal is Abundant, Silver is Rare
    if (hash1 <= 15 || hash1 > 45) {
      if (hash1 <= 10 && hash2 <= 10) {
        return SilverOreObjectID;
      }
    } else {
      if (hash2 > 0 && hash2 <= 15) {
        return CoalOreObjectID;
      }
    }
    return bytes32(0);
  }

  function oreRegion1Desert(int32 x, int32 y, int32 z) internal view returns (bytes32) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    // REGION 1: Coal is Abundant, Silver is Rare, Boost Gold Lightly
    if (hash1 <= 15 || hash1 > 45) {
      if (hash1 <= 10 && hash2 <= 10) {
        return SilverOreObjectID;
      } else if (hash1 <= 15 && hash2 <= 15) {
        return GoldOreObjectID;
      }
    } else {
      if (hash2 > 0 && hash2 <= 10) {
        return CoalOreObjectID;
      }
    }
    return bytes32(0);
  }

  function oreRegion1Mount(int32 x, int32 y, int32 z) internal view returns (bytes32) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    // REGION 1: Coal is Abundant, Silver is Rare But Boosted
    if (hash1 <= 15 || hash1 > 45) {
      if (hash1 <= 15 && hash2 <= 15) {
        return SilverOreObjectID;
      }
    } else {
      if (hash2 > 0 && hash2 <= 15) {
        return CoalOreObjectID;
      }
    }
    return bytes32(0);
  }

  function oreRegion2(int32 x, int32 y, int32 z) internal view returns (bytes32) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    // REGION 2: Coal and Silver Equally Abundant, Gold is Rare, Diamond is Even More Rare
    if (hash1 <= 25) {
      if (hash2 > 0 && hash2 <= 15) {
        return CoalOreObjectID;
      }
    } else if (hash1 > 25 && hash1 <= 50) {
      if (hash2 > 15 && hash2 <= 30) {
        return SilverOreObjectID;
      }
    } else if (hash1 > 45 && hash1 <= 60) {
      if (hash2 > 30 && hash2 <= 40) {
        return GoldOreObjectID;
      } else if (hash2 > 40 && hash2 <= 45) {
        return DiamondOreObjectID;
      }
    }
    return bytes32(0);
  }

  function oreRegion2Desert(int32 x, int32 y, int32 z) internal view returns (bytes32) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    // REGION 2: Coal and Silver Equally Abundant, Gold is Rare But Boosted, Diamond is Even More Rare
    if (hash1 <= 25) {
      if (hash2 > 0 && hash2 <= 15) {
        return CoalOreObjectID;
      }
    } else if (hash1 > 25 && hash1 <= 50) {
      if (hash2 > 15 && hash2 <= 30) {
        return SilverOreObjectID;
      } else if (hash2 > 30 && hash2 <= 45) {
        return GoldOreObjectID;
      }
    } else if (hash1 > 45 && hash1 <= 60) {
      if (hash2 > 45 && hash2 <= 50) {
        return DiamondOreObjectID;
      }
    }
    return bytes32(0);
  }

  function oreRegion2Mount(int32 x, int32 y, int32 z) internal view returns (bytes32) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    // REGION 2: Coal and Silver Equally Abundant, Gold is Rare, Diamond is Even More Rare but Boosted
    if (hash1 <= 25) {
      if (hash2 > 0 && hash2 <= 15) {
        return CoalOreObjectID;
      }
    } else if (hash1 > 25 && hash1 <= 50) {
      if (hash2 > 15 && hash2 <= 30) {
        return SilverOreObjectID;
      }
    } else if (hash1 > 45 && hash1 <= 60) {
      if (hash2 > 30 && hash2 <= 40) {
        return GoldOreObjectID;
      } else if (hash2 > 40 && hash2 <= 55) {
        return DiamondOreObjectID;
      }
    }
    return bytes32(0);
  }

  function oreRegion3(int32 x, int32 y, int32 z) internal view returns (bytes32) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    // REGION 3: Coal, Silver, and Gold Equally Abundant, Diamond is Rare, Neptunium is Even More Rare
    if (hash1 <= 25) {
      if (hash2 > 0 && hash2 <= 15) {
        return CoalOreObjectID;
      }
    } else if (hash1 > 25 && hash1 <= 50) {
      if (hash2 > 15 && hash2 <= 30) {
        return SilverOreObjectID;
      }
    } else if (hash1 > 50 && hash1 <= 75) {
      if (hash2 > 30 && hash2 <= 45) {
        return GoldOreObjectID;
      }
    } else if (hash1 > 75 && hash1 <= 90) {
      if (hash2 > 45 && hash2 <= 55) {
        return DiamondOreObjectID;
      } else if (hash2 > 55 && hash2 <= 60) {
        return NeptuniumOreObjectID;
      }
    }
    return bytes32(0);
  }

  function oreRegion3Desert(int32 x, int32 y, int32 z) internal view returns (bytes32) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    // REGION 3: Coal, Silver, and Gold Equally Abundant But Boosted Even More, Diamond is Rare, Neptunium is Even More Rare
    if (hash1 <= 25) {
      if (hash2 > 0 && hash2 <= 15) {
        return CoalOreObjectID;
      }
    } else if (hash1 > 25 && hash1 <= 50) {
      if (hash2 > 15 && hash2 <= 30) {
        return SilverOreObjectID;
      }
    } else if (hash1 > 50 && hash1 <= 75) {
      if (hash2 > 30 && hash2 <= 55) {
        return GoldOreObjectID;
      }
    } else if (hash1 > 75 && hash1 <= 90) {
      if (hash2 > 55 && hash2 <= 65) {
        return DiamondOreObjectID;
      } else if (hash2 > 65 && hash2 <= 70) {
        return NeptuniumOreObjectID;
      }
    }
    return bytes32(0);
  }

  function oreRegion3Mount(int32 x, int32 y, int32 z) internal view returns (bytes32) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    // REGION 3: Coal, Silver, and Gold Equally Abundant, Diamond is Rare, Neptunium is Even More Rare
    if (hash1 <= 25) {
      if (hash2 > 0 && hash2 <= 15) {
        return CoalOreObjectID;
      }
    } else if (hash1 > 25 && hash1 <= 50) {
      if (hash2 > 15 && hash2 <= 30) {
        return SilverOreObjectID;
      }
    } else if (hash1 > 50 && hash1 <= 75) {
      if (hash2 > 30 && hash2 <= 45) {
        return GoldOreObjectID;
      }
    } else if (hash1 > 75 && hash1 <= 90) {
      if (hash2 > 45 && hash2 <= 55) {
        return DiamondOreObjectID;
      } else if (hash2 > 55 && hash2 <= 70) {
        return NeptuniumOreObjectID;
      }
    }
    return bytes32(0);
  }
}
