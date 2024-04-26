import { Hex } from "viem";
import { setupNetwork } from "./setupNetwork";
import { SPAWN_HIGH_X, SPAWN_HIGH_Z, SPAWN_LOW_X, SPAWN_LOW_Z } from "./constants";
import prompts from "prompts";

async function main() {
  const { publicClient, worldAddress, IWorldAbi, account, txOptions, callTx } = await setupNetwork();

  // Calculate midpoints
  const spawnMidX = (SPAWN_LOW_X + SPAWN_HIGH_X) / 2;
  const spawnMidZ = (SPAWN_LOW_Z + SPAWN_HIGH_Z) / 2;

  const minY = 10;
  const maxY = 15;

  // 10 hours
  // const fullSize = { x: 300, y: maxY, z: 300 };

  // 6 hours
  const fullSize = { x: 150, y: maxY, z: 150 };

  // 40 minutes
  // const fullSize = { x: 50, y: maxY, z: 50 };
  // const fullSize = { x: 20, y: maxY, z: 20 };

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

  const respose = await prompts({
    type: "confirm",
    name: "continue",
    message: "Are you sure you want to continue?",
  });
  if (!respose.continue) {
    process.exit(0);
  }

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

        try {
          const currentCachedValue = await publicClient.readContract({
            address: worldAddress as Hex,
            abi: IWorldAbi,
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

          await callTx({
            ...txOptions,
            functionName: "fillTerrainCache",
            args: [lowerSouthWestCorner, size],
          });
        } catch (e) {
          console.log("Failed to fill", lowerSouthWestCorner, "with error", e);
        }
      }
    }
  }

  process.exit(0);
}

main();
