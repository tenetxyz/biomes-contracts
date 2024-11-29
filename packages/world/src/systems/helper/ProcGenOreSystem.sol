// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { NullObjectTypeId, WaterObjectID, SandObjectID, BellflowerObjectID, DandelionObjectID, DaylilyObjectID, RedMushroomObjectID, LilacObjectID, RoseObjectID, AzaleaObjectID, CactusObjectID, AirObjectID, SnowObjectID, BasaltObjectID, ClayBrickObjectID, CottonBlockObjectID, StoneObjectID, EmberstoneObjectID, CobblestoneObjectID, MoonstoneObjectID, GraniteObjectID, QuartziteObjectID, LimestoneObjectID, SunstoneObjectID, GravelObjectID, ClayObjectID, BedrockObjectID, DiamondOreObjectID, GoldOreObjectID, CoalOreObjectID, SilverOreObjectID, AnyOreObjectID, NeptuniumOreObjectID, GrassObjectID, MuckGrassObjectID, DirtObjectID, MuckDirtObjectID, MossBlockObjectID, CottonBushObjectID, SwitchGrassObjectID, OakLogObjectID, BirchLogObjectID, SakuraLogObjectID, RubberLogObjectID, OakLeafObjectID, BirchLeafObjectID, SakuraLeafObjectID, RubberLeafObjectID, LavaObjectID } from "../../ObjectTypeIds.sol";
import { Biome } from "../../Types.sol";

contract ProcGenOreSystem is System {
  function getCoordHash(int16 x, int16 z) internal pure returns (uint16) {
    uint256 hash = uint256(keccak256(abi.encode(x, z)));
    return uint16(hash % 1024);
  }

  function Ores(
    int16 x,
    int16 y,
    int16 z,
    int16 height,
    uint8 biome,
    int16 distanceFromHeight,
    uint256 randomNumber
  ) public view returns (uint8, uint8) {
    if (y >= height) return (NullObjectTypeId, NullObjectTypeId);

    // Checking biome conditions and distance from height for ore generation
    if (biome == uint8(Biome.Mountains)) {
      if (y > 10 && y <= 40) {
        return oreRegion1Mount(x, y, z, randomNumber);
      } else if (y > 40 && y <= 80) {
        return oreRegion2Mount(x, y, z, randomNumber);
      } else if (y > 80) {
        return oreRegion3Mount(x, y, z, randomNumber);
      }
    } else {
      if (distanceFromHeight >= 5 && distanceFromHeight <= 17) {
        if (biome == uint8(Biome.Desert)) {
          return oreRegion1Desert(x, y, z, randomNumber);
        } else {
          return oreRegion1(x, y, z, randomNumber);
        }
      } else if (distanceFromHeight > 17 && distanceFromHeight <= 40) {
        if (biome == uint8(Biome.Desert)) {
          return oreRegion2Desert(x, y, z, randomNumber);
        } else {
          return oreRegion2(x, y, z, randomNumber);
        }
      } else if (distanceFromHeight > 40) {
        if (biome == uint8(Biome.Desert)) {
          return oreRegion3Desert(x, y, z, randomNumber);
        } else {
          return oreRegion3(x, y, z, randomNumber);
        }
      }
    }

    return (NullObjectTypeId, NullObjectTypeId);
  }

  function oreRegion1(int16 x, int16 y, int16 z, uint256 randomNumber) internal view returns (uint8, uint8) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    uint8 oreObjectTypeId;
    if (randomNumber <= 71) {
      oreObjectTypeId = CoalOreObjectID;
    } else if (randomNumber >= 72 && randomNumber <= 99) {
      oreObjectTypeId = SilverOreObjectID;
    }

    // REGION 1: Coal is Abundant, Silver is Rare
    if (hash1 <= 20 || hash1 > 40) {
      if (hash1 <= 15 && hash2 <= 15) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    } else {
      if (hash2 > 0 && hash2 <= 20) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    }
    return (NullObjectTypeId, NullObjectTypeId);
  }

  function oreRegion1Desert(int16 x, int16 y, int16 z, uint256 randomNumber) internal view returns (uint8, uint8) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    uint8 oreObjectTypeId;
    if (randomNumber <= 71) {
      oreObjectTypeId = CoalOreObjectID;
    } else if (randomNumber >= 72 && randomNumber <= 94) {
      oreObjectTypeId = SilverOreObjectID;
    } else if (randomNumber >= 95 && randomNumber <= 99) {
      oreObjectTypeId = GoldOreObjectID;
    }

    // REGION 1: Coal is Abundant, Silver is Rare, Boost Gold Lightly
    if (hash1 <= 20 || hash1 > 40) {
      if (hash1 <= 15 && hash2 <= 15) {
        return (AnyOreObjectID, oreObjectTypeId);
      } else if (hash1 <= 5 && hash2 <= 5) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    } else {
      if (hash2 > 0 && hash2 <= 15) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    }
    return (NullObjectTypeId, NullObjectTypeId);
  }

  function oreRegion1Mount(int16 x, int16 y, int16 z, uint256 randomNumber) internal view returns (uint8, uint8) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    uint8 oreObjectTypeId;
    if (randomNumber <= 49) {
      oreObjectTypeId = CoalOreObjectID;
    } else if (randomNumber >= 50 && randomNumber <= 99) {
      oreObjectTypeId = SilverOreObjectID;
    }

    // REGION 1: Coal is Abundant, Silver is Rare But Boosted
    if (hash1 <= 20 || hash1 > 40) {
      if (hash1 <= 20 && hash2 <= 20) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    } else {
      if (hash2 > 0 && hash2 <= 20) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    }
    return (NullObjectTypeId, NullObjectTypeId);
  }

  function oreRegion2(int16 x, int16 y, int16 z, uint256 randomNumber) internal view returns (uint8, uint8) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    uint8 oreObjectTypeId;
    if (randomNumber <= 39) {
      oreObjectTypeId = CoalOreObjectID;
    } else if (randomNumber >= 40 && randomNumber <= 79) {
      oreObjectTypeId = SilverOreObjectID;
    } else if (randomNumber >= 80 && randomNumber <= 92) {
      oreObjectTypeId = GoldOreObjectID;
    } else if (randomNumber >= 93 && randomNumber <= 95) {
      oreObjectTypeId = DiamondOreObjectID;
    } else if (randomNumber >= 96 && randomNumber <= 99) {
      oreObjectTypeId = LavaObjectID;
    }

    // REGION 2: Coal and Silver Equally Abundant, Gold is Rare, Diamond is Even More Rare
    if (hash1 <= 30) {
      if (hash2 > 0 && hash2 <= 20) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    } else if (hash1 > 20 && hash1 <= 55) {
      if (hash2 > 10 && hash2 <= 35) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    } else if (hash1 > 40 && hash1 <= 65) {
      if (hash2 > 25 && hash2 <= 45) {
        return (AnyOreObjectID, oreObjectTypeId);
      } else if (hash2 > 35 && hash2 <= 50) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    }
    return (NullObjectTypeId, NullObjectTypeId);
  }

  function oreRegion2Desert(int16 x, int16 y, int16 z, uint256 randomNumber) internal view returns (uint8, uint8) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    uint8 oreObjectTypeId;
    if (randomNumber <= 37) {
      oreObjectTypeId = CoalOreObjectID;
    } else if (randomNumber >= 38 && randomNumber <= 72) {
      oreObjectTypeId = SilverOreObjectID;
    } else if (randomNumber >= 73 && randomNumber <= 85) {
      oreObjectTypeId = GoldOreObjectID;
    } else if (randomNumber >= 86 && randomNumber <= 94) {
      oreObjectTypeId = DiamondOreObjectID;
    } else if (randomNumber >= 95 && randomNumber <= 99) {
      oreObjectTypeId = LavaObjectID;
    }

    // REGION 2: Coal and Silver Equally Abundant, Gold is Rare But Boosted, Diamond is Even More Rare
    if (hash1 <= 30) {
      if (hash2 > 0 && hash2 <= 20) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    } else if (hash1 > 20 && hash1 <= 55) {
      if (hash2 > 10 && hash2 <= 35) {
        return (AnyOreObjectID, oreObjectTypeId);
      } else if (hash2 > 25 && hash2 <= 45) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    } else if (hash1 > 40 && hash1 <= 65) {
      if (hash2 > 40 && hash2 <= 55) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    }
    return (NullObjectTypeId, NullObjectTypeId);
  }

  function oreRegion2Mount(int16 x, int16 y, int16 z, uint256 randomNumber) internal view returns (uint8, uint8) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    uint8 oreObjectTypeId;
    if (randomNumber <= 24) {
      oreObjectTypeId = CoalOreObjectID;
    } else if (randomNumber >= 25 && randomNumber <= 74) {
      oreObjectTypeId = SilverOreObjectID;
    } else if (randomNumber >= 75 && randomNumber <= 86) {
      oreObjectTypeId = GoldOreObjectID;
    } else if (randomNumber >= 87 && randomNumber <= 95) {
      oreObjectTypeId = DiamondOreObjectID;
    } else if (randomNumber >= 96 && randomNumber <= 99) {
      oreObjectTypeId = LavaObjectID;
    }

    // REGION 2: Coal and Silver Equally Abundant, Gold is Rare, Diamond is Even More Rare but Boosted
    if (hash1 <= 20) {
      if (hash2 > 0 && hash2 <= 20) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    } else if (hash1 > 20 && hash1 <= 55) {
      if (hash2 > 10 && hash2 <= 35) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    } else if (hash1 > 40 && hash1 <= 65) {
      if (hash2 > 25 && hash2 <= 45) {
        return (AnyOreObjectID, oreObjectTypeId);
      } else if (hash2 > 35 && hash2 <= 60) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    }

    return (NullObjectTypeId, NullObjectTypeId);
  }

  function oreRegion3(int16 x, int16 y, int16 z, uint256 randomNumber) internal view returns (uint8, uint8) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    uint8 oreObjectTypeId;
    if (randomNumber <= 19) {
      oreObjectTypeId = CoalOreObjectID;
    } else if (randomNumber >= 20 && randomNumber <= 44) {
      oreObjectTypeId = SilverOreObjectID;
    } else if (randomNumber >= 45 && randomNumber <= 69) {
      oreObjectTypeId = GoldOreObjectID;
    } else if (randomNumber >= 70 && randomNumber <= 82) {
      oreObjectTypeId = DiamondOreObjectID;
    } else if (randomNumber >= 83 && randomNumber <= 85) {
      oreObjectTypeId = NeptuniumOreObjectID;
    } else if (randomNumber >= 86 && randomNumber <= 99) {
      oreObjectTypeId = LavaObjectID;
    }

    // REGION 3: Coal, Silver, and Gold Equally Abundant, Diamond is Rare, Neptunium is Even More Rare
    if (hash1 <= 30) {
      if (hash2 > 0 && hash2 <= 20) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    } else if (hash1 > 20 && hash1 <= 55) {
      if (hash2 > 10 && hash2 <= 35) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    } else if (hash1 > 45 && hash1 <= 80) {
      if (hash2 > 25 && hash2 <= 50) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    } else if (hash1 > 70 && hash1 <= 95) {
      if (hash2 > 40 && hash2 <= 60) {
        return (AnyOreObjectID, oreObjectTypeId);
      } else if (hash2 > 50 && hash2 <= 65) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    }
    return (NullObjectTypeId, NullObjectTypeId);
  }

  function oreRegion3Desert(int16 x, int16 y, int16 z, uint256 randomNumber) internal view returns (uint8, uint8) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    uint8 oreObjectTypeId;
    if (randomNumber <= 19) {
      oreObjectTypeId = CoalOreObjectID;
    } else if (randomNumber >= 20 && randomNumber <= 39) {
      oreObjectTypeId = SilverOreObjectID;
    } else if (randomNumber >= 40 && randomNumber <= 69) {
      oreObjectTypeId = GoldOreObjectID;
    } else if (randomNumber >= 70 && randomNumber <= 81) {
      oreObjectTypeId = DiamondOreObjectID;
    } else if (randomNumber >= 82 && randomNumber <= 84) {
      oreObjectTypeId = NeptuniumOreObjectID;
    } else if (randomNumber >= 85 && randomNumber <= 99) {
      oreObjectTypeId = LavaObjectID;
    }

    // REGION 3: Coal, Silver, and Gold Equally Abundant But Boosted Even More, Diamond is Rare, Neptunium is Even More Rare
    if (hash1 <= 30) {
      if (hash2 > 0 && hash2 <= 20) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    } else if (hash1 > 20 && hash1 <= 55) {
      if (hash2 > 10 && hash2 <= 35) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    } else if (hash1 > 45 && hash1 <= 80) {
      if (hash2 > 25 && hash2 <= 60) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    } else if (hash1 > 70 && hash1 <= 95) {
      if (hash2 > 50 && hash2 <= 70) {
        return (AnyOreObjectID, oreObjectTypeId);
      } else if (hash2 > 60 && hash2 <= 75) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    }
    return (NullObjectTypeId, NullObjectTypeId);
  }

  function oreRegion3Mount(int16 x, int16 y, int16 z, uint256 randomNumber) internal view returns (uint8, uint8) {
    uint16 hash1 = getCoordHash(x, z);
    uint16 hash2 = getCoordHash(y, x + z);

    uint8 oreObjectTypeId;
    if (randomNumber <= 19) {
      oreObjectTypeId = CoalOreObjectID;
    } else if (randomNumber >= 20 && randomNumber <= 44) {
      oreObjectTypeId = SilverOreObjectID;
    } else if (randomNumber >= 45 && randomNumber <= 69) {
      oreObjectTypeId = GoldOreObjectID;
    } else if (randomNumber >= 70 && randomNumber <= 82) {
      oreObjectTypeId = DiamondOreObjectID;
    } else if (randomNumber >= 83 && randomNumber <= 85) {
      oreObjectTypeId = NeptuniumOreObjectID;
    } else if (randomNumber >= 86 && randomNumber <= 99) {
      oreObjectTypeId = LavaObjectID;
    }

    // REGION 3: Coal, Silver, and Gold Equally Abundant, Diamond is Rare, Neptunium is Even More Rare
    if (hash1 <= 30) {
      if (hash2 > 0 && hash2 <= 20) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    } else if (hash1 > 20 && hash1 <= 55) {
      if (hash2 > 10 && hash2 <= 35) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    } else if (hash1 > 45 && hash1 <= 80) {
      if (hash2 > 25 && hash2 <= 50) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    } else if (hash1 > 70 && hash1 <= 95) {
      if (hash2 > 40 && hash2 <= 60) {
        return (AnyOreObjectID, oreObjectTypeId);
      } else if (hash2 > 50 && hash2 <= 75) {
        return (AnyOreObjectID, oreObjectTypeId);
      }
    }
    return (NullObjectTypeId, NullObjectTypeId);
  }
}
