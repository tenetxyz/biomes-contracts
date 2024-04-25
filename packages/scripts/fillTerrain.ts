import { Hex } from "viem";
import { setupNetwork } from "./setupNetwork";
import { SPAWN_HIGH_X, SPAWN_HIGH_Z, SPAWN_LOW_X, SPAWN_LOW_Z } from "./constants";

async function main() {
  const { publicClient, terrainWorldAddress, TerrainIWorldAbi, account, terrainTxOptions, callTx } =
    await setupNetwork();

  // Calculate midpoints
  const spawnMidX = (SPAWN_LOW_X + SPAWN_HIGH_X) / 2;
  const spawnMidZ = (SPAWN_LOW_Z + SPAWN_HIGH_Z) / 2;

  const minY = 0;
  const maxY = 25;

  // 10 hours
  // const fullSize = { x: 300, y: 25, z: 300 };

  // 4 hours
  // const fullSize = { x: 200, y: 25, z: 200 };

  // 16 minutes
  const fullSize = { x: 50, y: maxY, z: 50 };

  const startCorner = { x: Math.floor(spawnMidX - fullSize.x / 2), y: minY, z: Math.floor(spawnMidZ - fullSize.z / 2) };

  const chunkSize = 5;
  const rangeX = Math.ceil(fullSize.x / chunkSize);
  const rangeY = Math.ceil(fullSize.y / chunkSize);
  const rangeZ = Math.ceil(fullSize.z / chunkSize);
  console.log(
    "Covered Area:",
    JSON.stringify({
      lowerSouthwestCorner: startCorner,
      size: fullSize,
    })
  );

  const numTxs = rangeX * rangeY * rangeZ;
  console.log("Num Txs:", numTxs);
  const timePerTx = 5;
  const totalSeconds = numTxs * timePerTx;
  console.log("Total Time:", totalSeconds / 60, "minutes", totalSeconds / (60 * 60), "hours");

  let txCount = 0;
  for (let x = 0; x < rangeX; x++) {
    for (let y = 0; y < rangeY; y++) {
      for (let z = 0; z < rangeZ; z++) {
        txCount += 1;
        console.log("Tx", txCount, "of", numTxs, "(", Math.round((txCount / numTxs) * 100), "% )");
        const lowerSouthWestCorner = {
          x: startCorner.x + x * chunkSize,
          y: startCorner.y + y * chunkSize,
          z: startCorner.z + z * chunkSize,
        };
        const currentCachedValue = await publicClient.readContract({
          address: terrainWorldAddress as Hex,
          abi: TerrainIWorldAbi,
          functionName: "getCachedTerrainObjectTypeId",
          args: [lowerSouthWestCorner],
          account,
        });
        if (currentCachedValue != 0) {
          console.log("Skipping", lowerSouthWestCorner, "already filled");
          continue;
        }

        const size = { x: chunkSize, y: chunkSize, z: chunkSize };
        console.log("fillTerrainCache", lowerSouthWestCorner, size);

        try {
          await callTx({
            ...terrainTxOptions,
            functionName: "fillTerrainCache",
            args: [lowerSouthWestCorner, size],
          });
        } catch (e) {
          console.log("Error", e);
        }
      }
    }
  }

  process.exit(0);
}

main();
