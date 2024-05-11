import { getInfiniteTerrainBlock } from "./infinite";
import { Perlin, createPerlin } from "@latticexyz/noise";

async function main() {
  const perlin: Perlin = await createPerlin();

  const block = getInfiniteTerrainBlock({ x: 373, y: 17, z: -199 }, perlin);
  console.log(block);
}

main();
