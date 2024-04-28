import { Hex } from "viem";
import { setupNetwork } from "./setupNetwork";
import { SPAWN_HIGH_X, SPAWN_HIGH_Z, SPAWN_LOW_X, SPAWN_LOW_Z } from "./constants";
import prompts from "prompts";

async function main() {
  const { publicClient, worldAddress, IWorldAbi, account, txOptions, callTx } = await setupNetwork();

  // Calculate midpoints
  const spawnMidX = (SPAWN_LOW_X + SPAWN_HIGH_X) / 2;
  const spawnMidZ = (SPAWN_LOW_Z + SPAWN_HIGH_Z) / 2;

  // const minY = -10;
  // const maxY = 60;
  const minY = 10;
  const maxY = 20;

  // 10 hours
  // const fullSize = { x: 400, y: maxY, z: 400 };

  // 6 hours
  // const fullSize = { x: 150, y: maxY, z: 150 };

  // 40 minutes
  // const fullSize = { x: 50, y: maxY, z: 50 };
  const fullSize = { x: 40, y: maxY, z: 40 };

  const startCorner = { x: Math.floor(spawnMidX - fullSize.x / 2), y: minY, z: Math.floor(spawnMidZ - fullSize.z / 2) };
  // const startCorner = { x: Math.floor(spawnMidX - fullSize.x / 2), y: minY, z: SPAWN_LOW_Z - 30 };

  const chunkSize = { x: 5, y: 5, z: 5 };
  const rangeX = Math.ceil(fullSize.x / chunkSize.x);
  const rangeY = Math.ceil(fullSize.y / chunkSize.y);
  const rangeZ = Math.ceil(fullSize.z / chunkSize.z);
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

  let coords = [];

  for (let x = 0; x < fullSize.x; x++) {
    for (let z = 0; z < fullSize.z; z++) {
      for (let y = 0; y < fullSize.y; y++) {
        const coord = { x: startCorner.x + x, y: startCorner.y + y, z: startCorner.z + z };
        coords.push(coord);
        const objectTypeId = 35;
        if (coords.length == 1300) {
          // const objectTypeIds = coords.map(() => objectTypeId);
          await callTx({
            ...txOptions,
            functionName: "setTerrainObjectTypeIds",
            args: [coords, objectTypeId],
          });
          coords = [];
        }
      }
    }
  }

  // let txCount = 0;
  // for (let x = 0; x < rangeX; x++) {
  //   for (let y = 0; y < rangeY; y++) {
  //     for (let z = 0; z < rangeZ; z++) {
  //       txCount += 1;
  //       console.log("Tx", txCount, "of", numTxs, "(", Math.round((txCount / numTxs) * 100), "% )");
  //       const lowerSouthwestCorner = {
  //         x: startCorner.x + x * chunkSize.x,
  //         y: startCorner.y + y * chunkSize.y,
  //         z: startCorner.z + z * chunkSize.z,
  //       };

  //       try {
  //         const currentCachedValue = await publicClient.readContract({
  //           address: worldAddress as Hex,
  //           abi: IWorldAbi,
  //           functionName: "getCachedTerrainObjectTypeId",
  //           args: [lowerSouthwestCorner],
  //           account,
  //         });
  //         if (currentCachedValue != 0) {
  //           console.log("Skipping", lowerSouthwestCorner, "already filled");
  //           continue;
  //         }

  //         console.log("fillTerrainCache", lowerSouthwestCorner, chunkSize);

  //         await callTx({
  //           ...txOptions,
  //           // gas: 50_000_000n,
  //           functionName: "fillTerrainCache",
  //           args: [lowerSouthwestCorner, chunkSize],
  //         });
  //       } catch (e) {
  //         console.log("Failed to fill", lowerSouthwestCorner, "with error", e);
  //       }
  //     }
  //   }
  // }

  process.exit(0);
}

main();
