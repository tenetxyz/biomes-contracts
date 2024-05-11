export const AIR_OBJECT_ID = 34;
export const SNOW_OBJECT_ID = 40;
export const BASALT_OBJECT_ID = 55;
export const CLAY_BRICK_OBJECT_ID = 61;
export const COTTON_OBJECT_ID = 109;
export const STONE_OBJECT_ID = 50;
export const EMBERSTONE_OBJECT_ID = 80;
export const COBBLESTONE_OBJECT_ID = 45;
export const MOONSTONE_OBJECT_ID = 81;
export const GRANITE_OBJECT_ID = 65;
export const QUARTZITE_OBJECT_ID = 70;
export const LIMESTONE_OBJECT_ID = 75;
export const SUNSTONE_OBJECT_ID = 82;
export const GRAVEL_OBJECT_ID = 41;
export const CLAY_OBJECT_ID = 60;
export const BEDROCK_OBJECT_ID = 44;
export const WATER_OBJECT_ID = 83;
export const DIAMOND_ORE_OBJECT_ID = 93;
export const GOLD_ORE_OBJECT_ID = 89;
export const COAL_ORE_OBJECT_ID = 88;
export const SILVER_ORE_OBJECT_ID = 91;
export const NEPTUNIUM_ORE_OBJECT_ID = 95;
export const GRASS_OBJECT_ID = 35;
export const MUCK_GRASS_OBJECT_ID = 36;
export const DIRT_OBJECT_ID = 37;
export const MUCK_DIRT_OBJECT_ID = 38;
export const MOSS_OBJECT_ID = 39;
export const COTTON_BUSH_OBJECT_ID = 115;
export const SWITCH_GRASS_OBJECT_ID = 116;
export const OAK_LOG_OBJECT_ID = 97;
export const OAK_LUMBER_OBJECT_ID = 98;
export const BIRCH_LOG_OBJECT_ID = 105;
export const SAKURA_LOG_OBJECT_ID = 100;
export const RUBBER_LOG_OBJECT_ID = 102;
export const OAK_LEAF_OBJECT_ID = 120;
export const BIRCH_LEAF_OBJECT_ID = 121;
export const SAKURA_LEAF_OBJECT_ID = 122;
export const RUBBER_LEAF_OBJECT_ID = 123;
export const SAND_OBJECT_ID = 42;
export const CACTUS_OBJECT_ID = 110;
export const BELLFLOWER_OBJECT_ID = 114;
export const DANDELION_OBJECT_ID = 112;
export const DAYLILY_OBJECT_ID = 117;
export const RED_MUSHROOM_OBJECT_ID = 113;
export const LILAC_OBJECT_ID = 111;
export const ROSE_OBJECT_ID = 119;
export const AZALEA_OBJECT_ID = 118;

// Placeables
export const CHEST_OBJECT_ID = 84;
export const THERMOBLASTER_OBJECT_ID = 85;
export const WORKBENCH_OBJECT_ID = 86;
export const DYEOMATIC_OBJECT_ID = 87;
export const PLACEABLES_OBJECT_IDS = new Set([
  CHEST_OBJECT_ID,
  THERMOBLASTER_OBJECT_ID,
  WORKBENCH_OBJECT_ID,
  DYEOMATIC_OBJECT_ID,
]);

export const WOODEN_PICK_OBJECT_ID = 2;
export const WOODEN_AXE_OBJECT_ID = 3;
export const WOODEN_WHACKER_OBJECT_ID = 4;
export const STONE_PICK_OBJECT_ID = 5;
export const STONE_AXE_OBJECT_ID = 6;
export const STONE_WHACKER_OBJECT_ID = 7;
export const SILVER_PICK_OBJECT_ID = 8;
export const SILVER_AXE_OBJECT_ID = 9;
export const SILVER_WHACKER_OBJECT_ID = 10;
export const GOLD_PICK_OBJECT_ID = 11;
export const GOLD_AXE_OBJECT_ID = 12;
export const DIAMOND_PICK_OBJECT_ID = 13;
export const DIAMOND_AXE_OBJECT_ID = 14;
export const NEPTUNIUM_PICK_OBJECT_ID = 15;
export const NEPTUNIUM_AXE_OBJECT_ID = 16;

// For recipes only
export const ANY_LOG_OBJECT_ID = 159;
export const ANY_LUMBER_OBJECT_ID = 160;

export const TOOL_OBJECT_IDS = new Set([
  WOODEN_PICK_OBJECT_ID,
  WOODEN_AXE_OBJECT_ID,
  WOODEN_WHACKER_OBJECT_ID,
  STONE_PICK_OBJECT_ID,
  STONE_AXE_OBJECT_ID,
  STONE_WHACKER_OBJECT_ID,
  SILVER_PICK_OBJECT_ID,
  SILVER_AXE_OBJECT_ID,
  SILVER_WHACKER_OBJECT_ID,
  GOLD_PICK_OBJECT_ID,
  GOLD_AXE_OBJECT_ID,
  DIAMOND_PICK_OBJECT_ID,
  DIAMOND_AXE_OBJECT_ID,
  NEPTUNIUM_PICK_OBJECT_ID,
  NEPTUNIUM_AXE_OBJECT_ID,
]);

export const PLAYER_OBJECT_ID = 1;
export const AGENT_OBJECT_IDS = new Set([PLAYER_OBJECT_ID]);

// legacy
export type BiomesVariantData = number;
export const getBiomesVariantDataStrict = (id: number): BiomesVariantData => {
  return id;
};
