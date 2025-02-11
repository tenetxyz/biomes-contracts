import { SetupNetwork } from "../setupNetwork";
import { VoxelCoord } from "@latticexyz/utils";

export async function printSpawnCosts(
  setupNetwork: SetupNetwork,
  spawnCoord: VoxelCoord,
  preFillTerrain: boolean = false
) {
  const { txOptions, callTx, account } = setupNetwork;

  if (preFillTerrain) {
    await callTx(
      {
        ...txOptions,
        functionName: "computeTerrainObjectTypeIdWithSet",
        args: [spawnCoord],
      },
      "fill"
    );

    const belowCoord = { x: spawnCoord.x, y: spawnCoord.y - 1, z: spawnCoord.z };
    await callTx(
      {
        ...txOptions,
        functionName: "computeTerrainObjectTypeIdWithSet",
        args: [belowCoord],
      },
      "fill below"
    );
  }

  await callTx({
    ...txOptions,
    functionName: "spawnPlayer",
    args: [spawnCoord],
  });
}
