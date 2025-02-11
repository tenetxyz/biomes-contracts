import { VoxelCoord } from "@latticexyz/utils";
import { setupNetwork } from "./setupNetwork";

async function main() {
  const { txOptions, callTx } = await setupNetwork();

  console.log("Setting up spawn area...");

  const SPAWN_COORDS = [
    // (0, 0)
    { x: 236, y: 16, z: 332 },
    // (0, -1)
    { x: 2, y: 9, z: -517 },
    // (-1, 0)
    { x: -111, y: 27, z: 421 },
    // (-1, -1)
    { x: -35, y: 21, z: -206 },
  ];
  const SPAWN_SIZE = { x: 20, y: 0, z: 20 };

  for (const spawnCoord of SPAWN_COORDS) {
    await callTx(
      {
        ...txOptions,
        functionName: "addSpawn",
        args: [spawnCoord, SPAWN_SIZE],
      },
      `addSpawn ${spawnCoord.x}, ${spawnCoord.y}, ${spawnCoord.z}`,
    );

    await callTx({
      ...txOptions,
      functionName: "initSpawnAreaTop",
      args: [spawnCoord],
    });

    await callTx({
      ...txOptions,
      functionName: "initSpawnAreaTopPart2",
      args: [spawnCoord],
    });

    await callTx({
      ...txOptions,
      functionName: "initSpawnAreaTopAir",
      args: [spawnCoord],
    });

    await callTx({
      ...txOptions,
      functionName: "initSpawnAreaTopAirPart2",
      args: [spawnCoord],
    });

    await callTx({
      ...txOptions,
      functionName: "initSpawnAreaBottom",
      args: [spawnCoord],
    });

    await callTx({
      ...txOptions,
      functionName: "initSpawnAreaBottomPart2",
      args: [spawnCoord],
    });

    await callTx({
      ...txOptions,
      functionName: "initSpawnAreaBottomBorder",
      args: [spawnCoord],
    });
  }

  console.log("Spawn area setup complete.");

  process.exit(0);
}

main();
