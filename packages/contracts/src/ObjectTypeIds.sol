// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

// Object Types

// Players
bytes32 constant PlayerObjectID = bytes32(keccak256("player"));

// Tools
bytes32 constant WoodenPickObjectID = bytes32(keccak256("wooden-pick"));
bytes32 constant WoodenAxeObjectID = bytes32(keccak256("wooden-axe"));
bytes32 constant WoodenWhackerObjectID = bytes32(keccak256("wooden-whacker"));
bytes32 constant StonePickObjectID = bytes32(keccak256("stone-pick"));
bytes32 constant StoneAxeObjectID = bytes32(keccak256("stone-axe"));
bytes32 constant StoneWhackerObjectID = bytes32(keccak256("stone-pick"));
bytes32 constant SilverPickObjectID = bytes32(keccak256("silver-pick"));
bytes32 constant SilverAxeObjectID = bytes32(keccak256("silver-axe"));
bytes32 constant SilverWhackerObjectID = bytes32(keccak256("silver-whacker"));
bytes32 constant GoldPickObjectID = bytes32(keccak256("gold-pick"));
bytes32 constant GoldAxeObjectID = bytes32(keccak256("gold-axe"));
bytes32 constant DiamondPickObjectID = bytes32(keccak256("diamond-pick"));
bytes32 constant DiamondAxeObjectID = bytes32(keccak256("diamond-axe"));
bytes32 constant NeptuniumPickObjectID = bytes32(keccak256("neptunium-pick"));
bytes32 constant NeptuniumAxeObjectID = bytes32(keccak256("neptunium-axe"));

// Items
bytes32 constant GoldBarObjectID = bytes32(keccak256("gold-bar"));
bytes32 constant SilverBarObjectID = bytes32(keccak256("silver-ore"));
bytes32 constant NeptuniumBarObjectID = bytes32(keccak256("neptunium-bar"));
bytes32 constant DiamondObjectID = bytes32(keccak256("diamond"));
// Dyes
bytes32 constant BlueDyeObjectID = bytes32(keccak256("blue-dye"));
bytes32 constant BrownDyeObjectID = bytes32(keccak256("brown-dye"));
bytes32 constant GreenDyeObjectID = bytes32(keccak256("green-dye"));
bytes32 constant MagentaDyeObjectID = bytes32(keccak256("magenta-dye"));
bytes32 constant OrangeDyeObjectID = bytes32(keccak256("orange-dye"));
bytes32 constant PinkDyeObjectID = bytes32(keccak256("pink-dye"));
bytes32 constant PurpleDyeObjectID = bytes32(keccak256("purple-dye"));
bytes32 constant RedDyeObjectID = bytes32(keccak256("red-dye"));
bytes32 constant TanDyeObjectID = bytes32(keccak256("tan-dye"));
bytes32 constant WhiteDyeObjectID = bytes32(keccak256("white-dye"));
bytes32 constant YellowDyeObjectID = bytes32(keccak256("yellow-dye"));
bytes32 constant BlackDyeObjectID = bytes32(keccak256("black-dye"));
bytes32 constant SilverDyeObjectID = bytes32(keccak256("silver-dye"));

// Blocks
bytes32 constant AirObjectID = bytes32(keccak256("air"));

bytes32 constant GrassObjectID = bytes32(keccak256("grass"));
bytes32 constant MuckGrassObjectID = bytes32(keccak256("muck-grass"));
bytes32 constant DirtObjectID = bytes32(keccak256("dirt"));
bytes32 constant MuckDirtObjectID = bytes32(keccak256("muck-dirt"));
bytes32 constant MossObjectID = bytes32(keccak256("moss"));
bytes32 constant SnowObjectID = bytes32(keccak256("snow"));
bytes32 constant GravelObjectID = bytes32(keccak256("gravel"));
bytes32 constant AsphaltObjectID = bytes32(keccak256("asphalt"));
bytes32 constant SoilObjectID = bytes32(keccak256("soil"));
bytes32 constant SandObjectID = bytes32(keccak256("sand"));
bytes32 constant GlassObjectID = bytes32(keccak256("glass"));
bytes32 constant BedrockObjectID = bytes32(keccak256("bedrock"));

bytes32 constant CobblestoneObjectID = bytes32(keccak256("cobblestone"));
bytes32 constant CobblestoneBrickObjectID = bytes32(keccak256("cobblestone-brick"));

bytes32 constant StoneObjectID = bytes32(keccak256("stone"));
bytes32 constant StoneBrickObjectID = bytes32(keccak256("stone-brick"));
bytes32 constant StoneCarvedObjectID = bytes32(keccak256("stone-carved"));
bytes32 constant StonePolishedObjectID = bytes32(keccak256("stone-polished"));
bytes32 constant StoneShinglesObjectID = bytes32(keccak256("stone-shingles"));

bytes32 constant BasaltObjectID = bytes32(keccak256("basalt"));
bytes32 constant BasaltBrickObjectID = bytes32(keccak256("basalt-brick"));
bytes32 constant BasaltCarvedObjectID = bytes32(keccak256("basalt-carved"));
bytes32 constant BasaltPolishedObjectID = bytes32(keccak256("basalt-polished"));
bytes32 constant BasaltShinglesObjectID = bytes32(keccak256("basalt-shingles"));

bytes32 constant ClayObjectID = bytes32(keccak256("clay"));
bytes32 constant ClayBrickObjectID = bytes32(keccak256("clay-brick"));
bytes32 constant ClayCarvedObjectID = bytes32(keccak256("clay-carved"));
bytes32 constant ClayPolishedObjectID = bytes32(keccak256("clay-polished"));
bytes32 constant ClayShinglesObjectID = bytes32(keccak256("clay-shingles"));

bytes32 constant GraniteObjectID = bytes32(keccak256("granite"));
bytes32 constant GraniteBrickObjectID = bytes32(keccak256("granite-brick"));
bytes32 constant GraniteCarvedObjectID = bytes32(keccak256("granite-carved"));
bytes32 constant GraniteShinglesObjectID = bytes32(keccak256("granite-shingles"));
bytes32 constant GranitePolishedObjectID = bytes32(keccak256("granite-polished"));

bytes32 constant QuartziteObjectID = bytes32(keccak256("quartzite"));
bytes32 constant QuartziteBrickObjectID = bytes32(keccak256("quartzite-brick"));
bytes32 constant QuartziteCarvedObjectID = bytes32(keccak256("quartzite-carved"));
bytes32 constant QuartzitePolishedObjectID = bytes32(keccak256("quartzite-polished"));
bytes32 constant QuartziteShinglesObjectID = bytes32(keccak256("quartzite-shingles"));

bytes32 constant LimestoneObjectID = bytes32(keccak256("limestone"));
bytes32 constant LimestoneBrickObjectID = bytes32(keccak256("limestone-brick"));
bytes32 constant LimestoneCarvedObjectID = bytes32(keccak256("limestone-carved"));
bytes32 constant LimestonePolishedObjectID = bytes32(keccak256("limestone-polished"));
bytes32 constant LimestoneShinglesObjectID = bytes32(keccak256("limestone-shingles"));

// Blocks that glow
bytes32 constant EmberstoneObjectID = bytes32(keccak256("emberstone"));
bytes32 constant MoonstoneObjectID = bytes32(keccak256("moonstone"));
bytes32 constant SunstoneObjectID = bytes32(keccak256("sunstone"));
bytes32 constant LavaObjectID = bytes32(keccak256("lava"));

// Interactable
bytes32 constant ChestObjectID = bytes32(keccak256("chest"));
bytes32 constant ThermoblasterObjectID = bytes32(keccak256("thermoblaster"));
bytes32 constant WorkbenchObjectID = bytes32(keccak256("workbench"));
bytes32 constant DyeomaticObjectID = bytes32(keccak256("dye-o-matic"));

// Ores and Cubes
bytes32 constant CoalOreObjectID = bytes32(keccak256("coal-ore"));
bytes32 constant GoldOreObjectID = bytes32(keccak256("gold-ore"));
bytes32 constant GoldCubeObjectID = bytes32(keccak256("gold-cube"));
bytes32 constant SilverOreObjectID = bytes32(keccak256("silver-ore"));
bytes32 constant SilverCubeObjectID = bytes32(keccak256("silver-cube"));
bytes32 constant DiamondOreObjectID = bytes32(keccak256("diamond-ore"));
bytes32 constant DiamondCubeObjectID = bytes32(keccak256("diamond-cube"));
bytes32 constant NeptuniumOreObjectID = bytes32(keccak256("neptunium-ore"));
bytes32 constant NeptuniumCubeObjectID = bytes32(keccak256("neptunium-cube"));

// Lumber
bytes32 constant OakLogObjectID = bytes32(keccak256("oak-log"));
bytes32 constant OakLumberObjectID = bytes32(keccak256("oak-lumber"));
bytes32 constant ReinforcedOakLumberObjectID = bytes32(keccak256("reinforced-oak-lumber"));
bytes32 constant SakuraLogObjectID = bytes32(keccak256("sakura-log"));
bytes32 constant SakuraLumberObjectID = bytes32(keccak256("sakura-lumber"));
bytes32 constant RubberLogObjectID = bytes32(keccak256("rubber-log"));
bytes32 constant RubberLumberObjectID = bytes32(keccak256("rubber-lumber"));
bytes32 constant ReinforcedRubberLumberObjectID = bytes32(keccak256("reinforced-rubber-lumber"));
bytes32 constant BirchLogObjectID = bytes32(keccak256("birch-log"));
bytes32 constant BirchLumberObjectID = bytes32(keccak256("birch-lumber"));
bytes32 constant ReinforcedBirchLumberObjectID = bytes32(keccak256("reinforced-birch-lumber"));

// Florae blocks
bytes32 constant MushroomLeatherBlockObjectID = bytes32(keccak256("mushroom-leather"));
bytes32 constant CottonBlockObjectID = bytes32(keccak256("cotton-block"));

// Florae
bytes32 constant HempObjectID = bytes32(keccak256("hemp"));
bytes32 constant LilacObjectID = bytes32(keccak256("lilac"));
bytes32 constant DandelionObjectID = bytes32(keccak256("dandelion"));
bytes32 constant MuckshroomObjectID = bytes32(keccak256("muckshroom"));
bytes32 constant RedMushroomObjectID = bytes32(keccak256("red-mushroom"));
bytes32 constant BellflowerObjectID = bytes32(keccak256("bellflower"));
bytes32 constant CottonBushObjectID = bytes32(keccak256("cotton-bush"));
bytes32 constant MossGrassObjectID = bytes32(keccak256("moss-grass"));
bytes32 constant SwitchGrassObjectID = bytes32(keccak256("switch-grass"));
bytes32 constant DaylilyObjectID = bytes32(keccak256("daylily"));
bytes32 constant AzaleaObjectID = bytes32(keccak256("azalea"));
bytes32 constant RoseObjectID = bytes32(keccak256("rose"));

// Tree leafs
bytes32 constant OakLeafObjectID = bytes32(keccak256("oak-leaf"));
bytes32 constant BirchLeafObjectID = bytes32(keccak256("birch-leaf"));
bytes32 constant SakuraLeafObjectID = bytes32(keccak256("sakura-leaf"));
bytes32 constant RubberLeafObjectID = bytes32(keccak256("rubber-leaf"));

// Colored Blocks
bytes32 constant BlueOakLumberObjectID = bytes32(keccak256("blue-oak-lumber"));
bytes32 constant BrownOakLumberObjectID = bytes32(keccak256("brown-oak-lumber"));
bytes32 constant GreenOakLumberObjectID = bytes32(keccak256("green-oak-lumber"));
bytes32 constant MagentaOakLumberObjectID = bytes32(keccak256("magenta-oak-lumber"));
bytes32 constant OrangeOakLumberObjectID = bytes32(keccak256("orange-oak-lumber"));
bytes32 constant PinkOakLumberObjectID = bytes32(keccak256("pink-oak-lumber"));
bytes32 constant PurpleOakLumberObjectID = bytes32(keccak256("purple-oak-lumber"));
bytes32 constant RedOakLumberObjectID = bytes32(keccak256("red-oak-lumber"));
bytes32 constant TanOakLumberObjectID = bytes32(keccak256("tan-oak-lumber"));
bytes32 constant WhiteOakLumberObjectID = bytes32(keccak256("white-oak-lumber"));
bytes32 constant YellowOakLumberObjectID = bytes32(keccak256("yellow-oak-lumber"));
bytes32 constant BlackOakLumberObjectID = bytes32(keccak256("black-oak-lumber"));
bytes32 constant SilverOakLumberObjectID = bytes32(keccak256("silver-oak-lumber"));

bytes32 constant BlueCottonBlockObjectID = bytes32(keccak256("blue-cotton-block"));
bytes32 constant BrownCottonBlockObjectID = bytes32(keccak256("brown-cotton-block"));
bytes32 constant GreenCottonBlockObjectID = bytes32(keccak256("green-cotton-block"));
bytes32 constant MagentaCottonBlockObjectID = bytes32(keccak256("magenta-cotton-block"));
bytes32 constant OrangeCottonBlockObjectID = bytes32(keccak256("orange-cotton-block"));
bytes32 constant PinkCottonBlockObjectID = bytes32(keccak256("pink-cotton-block"));
bytes32 constant PurpleCottonBlockObjectID = bytes32(keccak256("purple-cotton-block"));
bytes32 constant RedCottonBlockObjectID = bytes32(keccak256("red-cotton-block"));
bytes32 constant TanCottonBlockObjectID = bytes32(keccak256("tan-cotton-block"));
bytes32 constant WhiteCottonBlockObjectID = bytes32(keccak256("white-cotton-block"));
bytes32 constant YellowCottonBlockObjectID = bytes32(keccak256("yellow-cotton-block"));
bytes32 constant BlackCottonBlockObjectID = bytes32(keccak256("black-cotton-block"));
bytes32 constant SilverCottonBlockObjectID = bytes32(keccak256("silver-cotton-block"));

bytes32 constant BlueGlassObjectID = bytes32(keccak256("blue-glass"));
bytes32 constant BrownGlassObjectID = bytes32(keccak256("brown-glass"));
bytes32 constant GreenGlassObjectID = bytes32(keccak256("green-glass"));
bytes32 constant MagentaGlassObjectID = bytes32(keccak256("magenta-glass"));
bytes32 constant OrangeGlassObjectID = bytes32(keccak256("orange-glass"));
bytes32 constant PinkGlassObjectID = bytes32(keccak256("pink-glass"));
bytes32 constant PurpleGlassObjectID = bytes32(keccak256("purple-glass"));
bytes32 constant RedGlassObjectID = bytes32(keccak256("red-glass"));
bytes32 constant TanGlassObjectID = bytes32(keccak256("tan-glass"));
bytes32 constant WhiteGlassObjectID = bytes32(keccak256("white-glass"));
bytes32 constant YellowGlassObjectID = bytes32(keccak256("yellow-glass"));
bytes32 constant BlackGlassObjectID = bytes32(keccak256("black-glass"));
bytes32 constant SilverGlassObjectID = bytes32(keccak256("silver-glass"));
