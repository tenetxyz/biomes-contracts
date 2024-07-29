import { Hex } from "viem";
import { setupNetwork } from "./setupNetwork";
import { ALL_SYSTEM_IDS, EMPTY_BYTES_32 } from "./constants";
import fs from "fs";
import prompts from "prompts";

async function main() {
  const { publicClient, worldAddress, IWorldAbi, account, txOptions, callTx } = await setupNetwork();

  const build = JSON.parse(fs.readFileSync("gen/build.json", "utf8"));

  const baseWorldCoord = build.baseWorldCoord;
  if (baseWorldCoord === undefined) {
    throw new Error("baseWorldCoord is not defined in build");
  }
  console.log(
    `Building ${build.relativePositions.length} blocks at ${baseWorldCoord.x}, ${baseWorldCoord.y}, ${baseWorldCoord.z}`,
  );

  const respose = await prompts({
    type: "confirm",
    name: "continue",
    message: "Are you sure you want to continue?",
  });
  if (!respose.continue) {
    process.exit(0);
  }

  let numTx = 0;

  for (let i = 0; i < build.relativePositions.length; i++) {
    const relativePos = build.relativePositions[i];
    const objectTypeId = build.objectTypeIds[i];

    const worldPos = {
      x: baseWorldCoord.x + relativePos.x,
      y: baseWorldCoord.y + relativePos.y,
      z: baseWorldCoord.z + relativePos.z,
    };

    const objectTypeIdAtCoord = await publicClient.readContract({
      address: worldAddress as Hex,
      abi: IWorldAbi,
      functionName: "getObjectTypeIdAtCoordOrTerrain",
      args: [worldPos],
      account,
    });
    if (objectTypeIdAtCoord === objectTypeId) {
      console.log(`Object ${objectTypeId} already exists at ${worldPos.x}, ${worldPos.y}, ${worldPos.z}`);
      continue;
    }

    numTx++;

    await callTx(
      {
        ...txOptions,
        functionName: "setObjectAtCoord",
        args: [objectTypeId, worldPos],
      },
      `Building object ${objectTypeId} at ${worldPos.x}, ${worldPos.y}, ${worldPos.z}`,
    );
  }

  console.log(`Finished! Sent ${numTx} transactions`);

  process.exit(0);
}

main();
