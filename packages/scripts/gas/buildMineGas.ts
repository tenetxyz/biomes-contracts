import { setupGasTest } from "./common";
import { VoxelCoord } from "@latticexyz/utils";

export async function printBuildMineGasCosts(
  preMoveCoords: VoxelCoord[],
  mineCoord: VoxelCoord,
  buildCoord: VoxelCoord,
  buildObjectType: number,
  preFillTerrain: boolean = false
) {
  const { spawnCoord, txOptions, callTx, account } = await setupGasTest();

  await callTx(
    {
      ...txOptions,
      functionName: "move",
      args: [preMoveCoords],
    },
    "pre move " + preMoveCoords.length
  );

  if (preFillTerrain) {
    await callTx(
      {
        ...txOptions,
        functionName: "fillObjectTypeWithComputedTerrainCache",
        args: [mineCoord],
      },
      "fill mine"
    );

    await callTx(
      {
        ...txOptions,
        functionName: "fillObjectTypeWithComputedTerrainCache",
        args: [buildCoord],
      },
      "fill build"
    );
  }

  await callTx({
    ...txOptions,
    functionName: "activatePlayer",
    args: [account.address],
  });

  await callTx({
    ...txOptions,
    functionName: "mine",
    args: [mineCoord],
  });

  await callTx({
    ...txOptions,
    functionName: "activatePlayer",
    args: [account.address],
  });

  await callTx({
    ...txOptions,
    functionName: "build",
    args: [buildObjectType, buildCoord],
  });
}
