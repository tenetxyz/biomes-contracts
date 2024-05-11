import { Perlin, createPerlin } from "@latticexyz/noise";
import { getTerrainBlock } from "./terrain";

async function main() {
  const perlin: Perlin = await createPerlin();

  const block = getTerrainBlock({ x: 373, y: 17, z: -199 }, perlin);
  console.log(block);
}

main();
