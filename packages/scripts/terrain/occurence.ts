import {
  AIR_OBJECT_ID,
  AZALEA_OBJECT_ID,
  BASALT_OBJECT_ID,
  BEDROCK_OBJECT_ID,
  BELLFLOWER_OBJECT_ID,
  BiomesVariantData,
  CACTUS_OBJECT_ID,
  COAL_ORE_OBJECT_ID,
  COTTON_BUSH_OBJECT_ID,
  DANDELION_OBJECT_ID,
  DAYLILY_OBJECT_ID,
  DIAMOND_ORE_OBJECT_ID,
  DIRT_OBJECT_ID,
  GOLD_ORE_OBJECT_ID,
  GRANITE_OBJECT_ID,
  GRASS_OBJECT_ID,
  GRAVEL_OBJECT_ID,
  LILAC_OBJECT_ID,
  LIMESTONE_OBJECT_ID,
  MOSS_OBJECT_ID,
  NEPTUNIUM_ORE_OBJECT_ID,
  QUARTZITE_OBJECT_ID,
  RED_MUSHROOM_OBJECT_ID,
  ROSE_OBJECT_ID,
  SAND_OBJECT_ID,
  SILVER_ORE_OBJECT_ID,
  STONE_OBJECT_ID,
  WATER_OBJECT_ID,
  getBiomesVariantDataStrict,
} from "./objectTypeIds";
import { Biome, STRUCTURE_CHUNK } from "./constants";
import { BirchTree, OakTree, RubberTree, SakuraTree, defineHashedPatch, getStructureBlock } from "./structures";
import { TerrainState } from "./types";
import { accessState } from "./utils";

export function Air(state: TerrainState): BiomesVariantData | undefined {
  const {
    coord: { y },
    height,
  } = state;
  if (y < height + 2 * STRUCTURE_CHUNK) return undefined;
  // if (y < height) return undefined;

  return getBiomesVariantDataStrict(AIR_OBJECT_ID);
}

export function TerrainBlocks(state: TerrainState): BiomesVariantData | undefined {
  const {
    coord: { y },
    height,
  } = state;
  if (y >= height) return undefined;

  if (y < -120) return getBiomesVariantDataStrict(BEDROCK_OBJECT_ID);

  const distanceFromHeight = accessState(state, "distanceFromHeight");
  const biome = accessState(state, "biome");

  if (distanceFromHeight <= 5) {
    if (distanceFromHeight == 1 && y > 0) {
      if (biome == Biome.Savanna) return getBiomesVariantDataStrict(GRASS_OBJECT_ID);
    }
    if (biome == Biome.Mountains) return getBiomesVariantDataStrict(STONE_OBJECT_ID);
    else if (biome == Biome.Forest && y > 0) return getBiomesVariantDataStrict(MOSS_OBJECT_ID);
  }

  if (biome == Biome.Mountains) {
    if (y <= -50) {
      return getBiomesVariantDataStrict(BASALT_OBJECT_ID);
    } else if (y <= 30) {
      return getBiomesVariantDataStrict(GRANITE_OBJECT_ID);
    } else if (y > 30 && y <= 80) {
      return getBiomesVariantDataStrict(LIMESTONE_OBJECT_ID);
    } else if (y > 80) {
      return getBiomesVariantDataStrict(QUARTZITE_OBJECT_ID);
    }
  } else if (biome == Biome.Desert) {
    if (y < 0) {
      return getBiomesVariantDataStrict(GRAVEL_OBJECT_ID);
    } else {
      return getBiomesVariantDataStrict(SAND_OBJECT_ID);
    }
  } else if (biome == Biome.Forest) {
    if (y < 0) {
      return getBiomesVariantDataStrict(DIRT_OBJECT_ID);
    } else {
      return getBiomesVariantDataStrict(DIRT_OBJECT_ID);
    }
  } else if (biome == Biome.Savanna) {
    if (y < 0) {
      return getBiomesVariantDataStrict(DIRT_OBJECT_ID);
    } else {
      return getBiomesVariantDataStrict(DIRT_OBJECT_ID);
    }
  }

  return undefined;
}

export function Water(state: TerrainState): BiomesVariantData | undefined {
  const {
    coord: { y },
    height,
  } = state;

  if (y < 0 && y >= height) return getBiomesVariantDataStrict(WATER_OBJECT_ID);
}

////////////////

export function Trees(state: TerrainState): BiomesVariantData | undefined {
  const {
    coord: { y },
    height,
  } = state;
  if (y < height || y < 0) return undefined;

  const chunkHeight = accessState(state, "chunkHeight");
  if (chunkHeight <= 0) return;

  const chunkOffset = accessState(state, "chunkOffset");
  const hash = accessState(state, "chunkHash");

  let structBlock = undefined;
  const biome = accessState(state, "biome");

  if (biome == Biome.Savanna) {
    if (hash >= 20) return undefined;
    structBlock = getStructureBlock(OakTree, chunkOffset);
  } else if (biome == Biome.Forest) {
    if (hash >= 300) return undefined;
    if (hash < 50) {
      structBlock = getStructureBlock(SakuraTree, chunkOffset);
    } else if (hash >= 50 && hash < 100) {
      structBlock = getStructureBlock(RubberTree, chunkOffset);
    } else if (hash >= 100 && hash < 150) {
      structBlock = getStructureBlock(BirchTree, chunkOffset);
    } else {
      structBlock = getStructureBlock(OakTree, chunkOffset);
    }
  }

  if (structBlock !== undefined) {
    return getBiomesVariantDataStrict(structBlock);
  }

  return undefined;
}

export function Flora(state: TerrainState): BiomesVariantData | undefined {
  const {
    coord: { y },
    height,
  } = state;

  if (y != height || y < 0) return undefined;

  const biome = accessState(state, "biome");
  const hash1 = accessState(state, "coordHash2D");
  const hash2 = accessState(state, "chunkHash2");
  const chunkOffset = accessState(state, "chunkOffset");
  let structBlock = undefined;

  if (biome == Biome.Desert) {
    if (hash1 < 6) {
      return getBiomesVariantDataStrict(CACTUS_OBJECT_ID);
    }
  } else if (biome == Biome.Savanna) {
    if (hash1 < 4) {
      return getBiomesVariantDataStrict(BELLFLOWER_OBJECT_ID);
    } else if (hash1 >= 4 && hash1 < 8) {
      return getBiomesVariantDataStrict(DANDELION_OBJECT_ID);
    } else if (hash1 >= 8 && hash1 < 12) {
      return getBiomesVariantDataStrict(DAYLILY_OBJECT_ID);
    } else if (hash1 >= 12 && hash1 < 16) {
      return getBiomesVariantDataStrict(RED_MUSHROOM_OBJECT_ID);
    } else if (hash1 >= 16 && hash1 < 20) {
      return getBiomesVariantDataStrict(LILAC_OBJECT_ID);
    } else if (hash1 >= 20 && hash1 < 24) {
      return getBiomesVariantDataStrict(ROSE_OBJECT_ID);
    } else if (hash1 >= 24 && hash1 < 28) {
      return getBiomesVariantDataStrict(AZALEA_OBJECT_ID);
    }
  } else if (biome == Biome.Mountains) {
    if (hash2 >= 30) return undefined;
    const chunkHeight = accessState(state, "chunkHeight");
    if (chunkHeight <= 0) return;

    structBlock = getStructureBlock(defineHashedPatch(state, COTTON_BUSH_OBJECT_ID), chunkOffset);

    if (structBlock !== undefined) {
      return getBiomesVariantDataStrict(structBlock);
    }

    return undefined;
  }

  return undefined;
}

//////////////////

function oreRegion1(state: TerrainState): BiomesVariantData | undefined {
  const hash1 = accessState(state, "coordHash2D");
  const hash2 = accessState(state, "coordHash1D");

  //REGION 1: Coal is Abundant, Silver is Rare

  if (hash1 <= 20 || hash1 > 40) {
    if (hash1 <= 15 && hash2 <= 15) {
      return getBiomesVariantDataStrict(SILVER_ORE_OBJECT_ID);
    }
  } else {
    if (hash2 > 0 && hash2 <= 20) {
      return getBiomesVariantDataStrict(COAL_ORE_OBJECT_ID);
    }
  }

  return undefined;
}

function oreRegion1Desert(state: TerrainState): BiomesVariantData | undefined {
  const hash1 = accessState(state, "coordHash2D");
  const hash2 = accessState(state, "coordHash1D");

  //REGION 1: Coal is Abundant, Silver is Rare, Boost Gold Lightly

  if (hash1 <= 20 || hash1 > 40) {
    if (hash1 <= 15 && hash2 <= 15) {
      return getBiomesVariantDataStrict(SILVER_ORE_OBJECT_ID);
    } else if (hash1 <= 5 && hash2 <= 5) {
      return getBiomesVariantDataStrict(GOLD_ORE_OBJECT_ID);
    }
  } else {
    if (hash2 > 0 && hash2 <= 15) {
      return getBiomesVariantDataStrict(COAL_ORE_OBJECT_ID);
    }
  }

  return undefined;
}

function oreRegion1Mount(state: TerrainState): BiomesVariantData | undefined {
  const hash1 = accessState(state, "coordHash2D");
  const hash2 = accessState(state, "coordHash1D");

  //REGION 1: Coal is Abundant, Silver is Rare But Boosted

  if (hash1 <= 20 || hash1 > 40) {
    if (hash1 <= 20 && hash2 <= 20) {
      return getBiomesVariantDataStrict(SILVER_ORE_OBJECT_ID);
    }
  } else {
    if (hash2 > 0 && hash2 <= 20) {
      return getBiomesVariantDataStrict(COAL_ORE_OBJECT_ID);
    }
  }

  return undefined;
}

function oreRegion2Desert(state: TerrainState): BiomesVariantData | undefined {
  const hash1 = accessState(state, "coordHash2D");
  const hash2 = accessState(state, "coordHash1D");

  //REGION 2: Coal and Silver Equally Abundant, Gold is Rare But Boosted, Diamond is Even More Rare

  if (hash1 <= 30) {
    if (hash2 > 0 && hash2 <= 20) {
      return getBiomesVariantDataStrict(COAL_ORE_OBJECT_ID);
    }
  } else if (hash1 > 20 && hash1 <= 55) {
    if (hash2 > 10 && hash2 <= 35) {
      return getBiomesVariantDataStrict(SILVER_ORE_OBJECT_ID);
    } else if (hash2 > 25 && hash2 <= 45) {
      return getBiomesVariantDataStrict(GOLD_ORE_OBJECT_ID);
    }
  } else if (hash1 > 40 && hash1 <= 65) {
    if (hash2 > 40 && hash2 <= 55) {
      return getBiomesVariantDataStrict(DIAMOND_ORE_OBJECT_ID);
    }
  }

  return undefined;
}

function oreRegion2(state: TerrainState): BiomesVariantData | undefined {
  const hash1 = accessState(state, "coordHash2D");
  const hash2 = accessState(state, "coordHash1D");

  //REGION 2: Coal and Silver Equally Abundant, Gold is Rare, Diamond is Even More Rare

  if (hash1 <= 30) {
    if (hash2 > 0 && hash2 <= 20) {
      return getBiomesVariantDataStrict(COAL_ORE_OBJECT_ID);
    }
  } else if (hash1 > 20 && hash1 <= 55) {
    if (hash2 > 10 && hash2 <= 35) {
      return getBiomesVariantDataStrict(SILVER_ORE_OBJECT_ID);
    }
  } else if (hash1 > 40 && hash1 <= 65) {
    if (hash2 > 25 && hash2 <= 45) {
      return getBiomesVariantDataStrict(GOLD_ORE_OBJECT_ID);
    } else if (hash2 > 35 && hash2 <= 50) {
      return getBiomesVariantDataStrict(DIAMOND_ORE_OBJECT_ID);
    }
  }

  return undefined;
}

function oreRegion2Mount(state: TerrainState): BiomesVariantData | undefined {
  const hash1 = accessState(state, "coordHash2D");
  const hash2 = accessState(state, "coordHash1D");

  //REGION 2: Coal and Silver Equally Abundant, Gold is Rare, Diamond is Even More Rare but Boosted

  if (hash1 <= 20) {
    if (hash2 > 0 && hash2 <= 20) {
      return getBiomesVariantDataStrict(COAL_ORE_OBJECT_ID);
    }
  } else if (hash1 > 20 && hash1 <= 55) {
    if (hash2 > 10 && hash2 <= 35) {
      return getBiomesVariantDataStrict(SILVER_ORE_OBJECT_ID);
    }
  } else if (hash1 > 40 && hash1 <= 65) {
    if (hash2 > 25 && hash2 <= 45) {
      return getBiomesVariantDataStrict(GOLD_ORE_OBJECT_ID);
    } else if (hash2 > 35 && hash2 <= 60) {
      return getBiomesVariantDataStrict(DIAMOND_ORE_OBJECT_ID);
    }
  }

  return undefined;
}

function oreRegion3(state: TerrainState): BiomesVariantData | undefined {
  const hash1 = accessState(state, "coordHash2D");
  const hash2 = accessState(state, "coordHash1D");

  //REGION 3: Coal, Silver, and Gold Equally Abundant, Diamond is Rare, Neptunium is Even More Rare

  if (hash1 <= 30) {
    if (hash2 > 0 && hash2 <= 20) {
      return getBiomesVariantDataStrict(COAL_ORE_OBJECT_ID);
    }
  } else if (hash1 > 20 && hash1 <= 55) {
    if (hash2 > 10 && hash2 <= 35) {
      return getBiomesVariantDataStrict(SILVER_ORE_OBJECT_ID);
    }
  } else if (hash1 > 45 && hash1 <= 80) {
    if (hash2 > 25 && hash2 <= 50) {
      return getBiomesVariantDataStrict(GOLD_ORE_OBJECT_ID);
    }
  } else if (hash1 > 70 && hash1 <= 95) {
    if (hash2 > 40 && hash2 <= 60) {
      return getBiomesVariantDataStrict(DIAMOND_ORE_OBJECT_ID);
    } else if (hash2 > 50 && hash2 <= 65) {
      return getBiomesVariantDataStrict(NEPTUNIUM_ORE_OBJECT_ID);
    }
  }

  return undefined;
}

function oreRegion3Desert(state: TerrainState): BiomesVariantData | undefined {
  const hash1 = accessState(state, "coordHash2D");
  const hash2 = accessState(state, "coordHash1D");

  //REGION 3: Coal, Silver, and Gold Equally Abundant But Boosted Even More, Diamond is Rare, Neptunium is Even More Rare

  if (hash1 <= 30) {
    if (hash2 > 0 && hash2 <= 20) {
      return getBiomesVariantDataStrict(COAL_ORE_OBJECT_ID);
    }
  } else if (hash1 > 20 && hash1 <= 55) {
    if (hash2 > 10 && hash2 <= 35) {
      return getBiomesVariantDataStrict(SILVER_ORE_OBJECT_ID);
    }
  } else if (hash1 > 45 && hash1 <= 80) {
    if (hash2 > 25 && hash2 <= 60) {
      return getBiomesVariantDataStrict(GOLD_ORE_OBJECT_ID);
    }
  } else if (hash1 > 70 && hash1 <= 95) {
    if (hash2 > 50 && hash2 <= 70) {
      return getBiomesVariantDataStrict(DIAMOND_ORE_OBJECT_ID);
    } else if (hash2 > 60 && hash2 <= 75) {
      return getBiomesVariantDataStrict(NEPTUNIUM_ORE_OBJECT_ID);
    }
  }

  return undefined;
}

function oreRegion3Mount(state: TerrainState): BiomesVariantData | undefined {
  const hash1 = accessState(state, "coordHash2D");
  const hash2 = accessState(state, "coordHash1D");

  //REGION 3: Coal, Silver, and Gold Equally Abundant, Diamond is Rare, Neptunium is Even More Rare

  if (hash1 <= 30) {
    if (hash2 > 0 && hash2 <= 20) {
      return getBiomesVariantDataStrict(COAL_ORE_OBJECT_ID);
    }
  } else if (hash1 > 20 && hash1 <= 55) {
    if (hash2 > 10 && hash2 <= 35) {
      return getBiomesVariantDataStrict(SILVER_ORE_OBJECT_ID);
    }
  } else if (hash1 > 45 && hash1 <= 80) {
    if (hash2 > 25 && hash2 <= 50) {
      return getBiomesVariantDataStrict(GOLD_ORE_OBJECT_ID);
    }
  } else if (hash1 > 70 && hash1 <= 95) {
    if (hash2 > 40 && hash2 <= 60) {
      return getBiomesVariantDataStrict(DIAMOND_ORE_OBJECT_ID);
    } else if (hash2 > 50 && hash2 <= 75) {
      return getBiomesVariantDataStrict(NEPTUNIUM_ORE_OBJECT_ID);
    }
  }

  return undefined;
}

export function Ores(state: TerrainState): BiomesVariantData | undefined {
  const {
    coord: { y },
    height,
  } = state;
  if (y >= height) return undefined;

  const biome = accessState(state, "biome");
  const distanceFromHeight = accessState(state, "distanceFromHeight");

  if (biome == Biome.Mountains) {
    if (y > 10 && y <= 40) {
      return oreRegion1Mount(state);
    } else if (y > 40 && y <= 80) {
      return oreRegion2Mount(state);
    } else if (y > 80) {
      return oreRegion3Mount(state);
    }
  } else {
    if (distanceFromHeight >= 5 && distanceFromHeight <= 17) {
      if (biome == Biome.Desert) {
        return oreRegion1Desert(state);
      } else {
        return oreRegion1(state);
      }
    } else if (distanceFromHeight > 17 && distanceFromHeight <= 40) {
      if (biome == Biome.Desert) {
        return oreRegion2Desert(state);
      } else {
        return oreRegion2(state);
      }
    } else if (distanceFromHeight > 40) {
      if (biome == Biome.Desert) {
        return oreRegion3Desert(state);
      } else {
        return oreRegion3(state);
      }
    }
  }

  return undefined;
}
