import { Hex } from "viem";
import { setupNetwork } from "./setupNetwork";
import prompts from "prompts";
import fs from "fs";
import { VoxelCoord } from "@latticexyz/utils";

const maxTerrainVolume = 1331; // 11^3
const maxCoordsInOneTx = 1300;

const singleTxFee = 0.00005614070453336; // ETH
const singleTxFeeNoPriority = 0.00001231957591901; // ETH
const areaTxFee = 0.00004031227105893; // 1 ETH
const areaTxFeeNoPriority = 0.00000002173463148; // ETH
// Safer values
// const maxTerrainVolume = 1000; // 10^3
// const maxCoordsInOneTx = 1200;

function splitArea(area: any) {
  const { lowerSouthwestCorner, size, objectTypeId } = area;
  // console.log("Splitting area", area);
  const { x, y, z } = size;
  const maxSize = Math.max(x, y, z);
  const newSize = {};

  if (maxSize === x) {
    newSize.x = Math.ceil(x / 2);
    newSize.y = y;
    newSize.z = z;
  } else if (maxSize === y) {
    newSize.x = x;
    newSize.y = Math.ceil(y / 2);
    newSize.z = z;
  } else {
    newSize.x = x;
    newSize.y = y;
    newSize.z = Math.ceil(z / 2);
  }

  const newArea1 = {
    lowerSouthwestCorner,
    size: newSize,
    objectTypeId,
  };

  const newLowerCorner = { ...lowerSouthwestCorner };
  if (maxSize === x) {
    newLowerCorner.x += newSize.x;
  } else if (maxSize === y) {
    newLowerCorner.y += newSize.y;
  } else {
    newLowerCorner.z += newSize.z;
  }

  const newArea2 = {
    lowerSouthwestCorner: newLowerCorner,
    size: {
      ...size,
      [maxSize === x ? "x" : maxSize === y ? "y" : "z"]: Math.floor(
        size[maxSize === x ? "x" : maxSize === y ? "y" : "z"] / 2
      ),
    },
    objectTypeId,
  };

  // console.log("New areas", newArea1, newArea2);

  return [newArea1, newArea2];
}

async function applyTerrainTxes(
  terrainTxes: any,
  skipExisting: boolean,
  dryRun: boolean = false
): Promise<[number, VoxelCoord[]]> {
  const { publicClient, worldAddress, IWorldAbi, account, txOptions, callTx } = await setupNetwork();

  let numTxes: number = 0;
  let areasToProcess = [...terrainTxes["areas"]]; // Clone the original areas list
  let coordsCovered: VoxelCoord[] = [];
  let objectTypeTxs = new Map();

  while (areasToProcess.length > 0) {
    const terrainTxArea = areasToProcess.shift();
    const { lowerSouthwestCorner, size, objectTypeId } = terrainTxArea;
    const areaVolume = size.x * size.y * size.z;

    if (areaVolume > maxTerrainVolume) {
      const newAreas = splitArea(terrainTxArea);
      areasToProcess.push(...newAreas);
      continue;
    }

    numTxes++;
    let newTxCount = objectTypeTxs.get(objectTypeId.toString());
    if (newTxCount === undefined) {
      newTxCount = {
        areaCount: 0,
        singleCount: 0,
      };
    }
    newTxCount.areaCount++;
    objectTypeTxs.set(objectTypeId.toString(), newTxCount);

    for (let x = lowerSouthwestCorner.x; x < lowerSouthwestCorner.x + size.x; x++) {
      for (let y = lowerSouthwestCorner.y; y < lowerSouthwestCorner.y + size.y; y++) {
        for (let z = lowerSouthwestCorner.z; z < lowerSouthwestCorner.z + size.z; z++) {
          coordsCovered.push({ x, y, z });
        }
      }
    }

    if (dryRun) {
      continue;
    }

    // check if these coords are already set
    if (skipExisting) {
      let numCoordsAlreadySet = 0;
      console.log("Checking if coords are already set", objectTypeId, lowerSouthwestCorner, size);
      for (let x = lowerSouthwestCorner.x; x < lowerSouthwestCorner.x + size.x; x++) {
        for (let y = lowerSouthwestCorner.y; y < lowerSouthwestCorner.y + size.y; y++) {
          for (let z = lowerSouthwestCorner.z; z < lowerSouthwestCorner.z + size.z; z++) {
            const cachedObjectType = await publicClient.readContract({
              address: worldAddress as Hex,
              abi: IWorldAbi,
              functionName: "getCachedTerrainObjectTypeId",
              args: [{ x, y, z }],
              account,
            });
            // remove ones that are already set
            if (cachedObjectType === Number(objectTypeId)) {
              numCoordsAlreadySet++;
            }
          }
        }
      }
      if (numCoordsAlreadySet === areaVolume) {
        console.log("All coords already set", objectTypeId, lowerSouthwestCorner, size);
        continue;
      }
      if (numCoordsAlreadySet > 0) {
        console.log("Some coords already set", numCoordsAlreadySet, objectTypeId, lowerSouthwestCorner, size);
      }
    }

    await callTx(
      {
        ...txOptions,
        functionName: "setTerrainObjectTypeIds",
        args: [lowerSouthwestCorner, size, objectTypeId],
      },
      "setTerrainObjectTypeIds area"
    );
  }

  for (const [objectTypeId, coords] of Object.entries(terrainTxes["singles"])) {
    const coordsLength = coords.length;
    let coordsIndex = 0;
    while (coordsIndex < coordsLength) {
      let coordsToSend = [];
      for (let i = 0; i < maxCoordsInOneTx && coordsIndex < coordsLength; i++) {
        coordsToSend.push(coords[coordsIndex]);
        coordsIndex++;
      }
      numTxes++;
      let newTxCount = objectTypeTxs.get(objectTypeId.toString());
      if (newTxCount === undefined) {
        newTxCount = {
          areaCount: 0,
          singleCount: 0,
        };
      }
      newTxCount.singleCount++;
      objectTypeTxs.set(objectTypeId.toString(), newTxCount);

      coordsCovered.push(...coordsToSend);

      if (dryRun) {
        continue;
      }

      // check if these coords are already set
      if (skipExisting) {
        let removed = 0;
        console.log("Checking if coords are already set", objectTypeId, coordsToSend.length, coordsToSend);
        for (const coord of coordsToSend) {
          const cachedObjectType = await publicClient.readContract({
            address: worldAddress as Hex,
            abi: IWorldAbi,
            functionName: "getCachedTerrainObjectTypeId",
            args: [coord],
            account,
          });
          // remove ones that are already set
          if (cachedObjectType === Number(objectTypeId)) {
            coordsToSend = coordsToSend.filter((c) => c !== coord);
            removed++;
          }
        }
        if (coordsToSend.length === 0) {
          console.log("All coords already set", objectTypeId, coordsToSend);
          continue;
        }
        if (removed > 0) {
          console.log("Removed", removed, "coords that were already set", objectTypeId, coordsToSend);
        }
      }

      await callTx(
        {
          ...txOptions,
          functionName: "setTerrainObjectTypeIds",
          args: [coordsToSend, Number(objectTypeId)],
        },
        "setTerrainObjectTypeIds single"
      );
    }
  }

  return [numTxes, coordsCovered, objectTypeTxs];
}

async function main() {
  // Load pre-calculated tx's from terrain_txs.json
  const terrainTxes = JSON.parse(fs.readFileSync("terrain_txs.json", "utf8"));
  console.log("Terrain tx's read from file.");

  const [numTxs, coordsCovered, objectTypeTxs] = await applyTerrainTxes(terrainTxes, false, true);
  console.log("Num tx's to apply:", numTxs);
  console.log("Coords to be covered:", coordsCovered.length.toLocaleString());
  console.log("objectTypeTxs", objectTypeTxs);
  const timePerTx = 5;
  const totalSeconds = numTxs * timePerTx;
  console.log("Total Time:", totalSeconds / 60, "minutes", totalSeconds / (60 * 60), "hours");

  let numAreaTxs = 0;
  let numSingleTxs = 0;
  objectTypeTxs.forEach((value) => {
    numAreaTxs += value.areaCount;
    numSingleTxs += value.singleCount;
  });
  if (numAreaTxs + numSingleTxs != numTxs) {
    throw new Error("Number of area txs and single txs do not match total txs");
  }
  console.log("Area Tx Cost:", numAreaTxs * areaTxFee, "ETH");
  console.log("Single Tx Cost:", numSingleTxs * singleTxFee, "ETH");

  const respose = await prompts({
    type: "confirm",
    name: "continue",
    message: "Are you sure you want to continue?",
  });
  if (!respose.continue) {
    process.exit(0);
  }

  await applyTerrainTxes(terrainTxes, false, false);

  process.exit(0);
}

main();
