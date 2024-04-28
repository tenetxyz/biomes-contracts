import { Hex } from "viem";
import { setupNetwork } from "./setupNetwork";
import prompts from "prompts";
import fs from "fs";

const maxTerrainVolume = 1331; // 11^3
const maxCoordsInOneTx = 1300;

// Safer values
// const maxTerrainVolume = 1000; // 10^3
// const maxCoordsInOneTx = 1200;

async function applyTerrainTxes(terrainTxes: any, dryRun: boolean = false) {
  const { publicClient, worldAddress, IWorldAbi, account, txOptions, callTx } = await setupNetwork();

  let numTxes: number = 0;
  for (const terrainTxArea of terrainTxes["areas"]) {
    const lowerSouthmostCorner = terrainTxArea.lowerSouthwestCorner;
    const size = terrainTxArea.size;
    const objectTypeId = terrainTxArea.objectTypeId;
    const areaVolume = size.x * size.y * size.z;
    if (areaVolume > maxTerrainVolume) {
      console.log("Area too large, skipping.");
      continue;
    }
    numTxes++;
    if (dryRun) {
      continue;
    }

    await callTx({
      ...txOptions,
      functionName: "setTerrainObjectTypeIds",
      args: [lowerSouthmostCorner, size, objectTypeId],
    });
  }

  for (const [objectTypeId, coords] of Object.entries(terrainTxes["singles"])) {
    const coordsLength = coords.length;
    let coordsIndex = 0;
    while (coordsIndex < coordsLength) {
      const coordsToSend = [];
      for (let i = 0; i < maxCoordsInOneTx && coordsIndex < coordsLength; i++) {
        coordsToSend.push(coords[coordsIndex]);
        coordsIndex++;
      }
      numTxes++;
      if (dryRun) {
        continue;
      }

      await callTx({
        ...txOptions,
        functionName: "setTerrainObjectTypeIds",
        args: [coordsToSend, Number(objectTypeId)],
      });
    }
  }

  return numTxes;
}

async function main() {
  const { publicClient, worldAddress, IWorldAbi, account, txOptions, callTx } = await setupNetwork();

  // Load pre-calculated tx's from terrain_txs.json
  const terrainTxes = JSON.parse(fs.readFileSync("terrain_txs.json", "utf8"));
  console.log("Terrain tx's read from file.");

  const numTxs = await applyTerrainTxes(terrainTxes, true);
  console.log("Num tx's to apply:", numTxs);
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

  await applyTerrainTxes(terrainTxes, false);

  process.exit(0);
}

main();
