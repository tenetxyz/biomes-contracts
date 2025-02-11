import { SetupNetwork, setupNetwork } from "../setupNetwork";
import { VoxelCoord } from "@latticexyz/utils";

export async function printBuildMineGasCosts(
  setupNetwork: SetupNetwork,
  mineCoord: VoxelCoord,
  buildCoord: VoxelCoord,
  buildObjectType: number,
  preFillTerrain: boolean = false
) {
  const { txOptions, callTx, account } = setupNetwork;

  if (preFillTerrain) {
    await callTx(
      {
        ...txOptions,
        functionName: "computeTerrainObjectTypeIdWithSet",
        args: [mineCoord],
      },
      "fill mine"
    );

    await callTx(
      {
        ...txOptions,
        functionName: "computeTerrainObjectTypeIdWithSet",
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
