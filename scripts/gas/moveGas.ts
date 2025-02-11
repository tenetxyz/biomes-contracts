import { SetupNetwork } from "../setupNetwork";
import { VoxelCoord } from "@latticexyz/utils";

export async function printMoveGasCosts(
  setupNetwork: SetupNetwork,
  moveCoords: VoxelCoord[],
  preFillTerrain: boolean = false
) {
  const { txOptions, callTx, account } = setupNetwork;

  for (let i = 0; i < moveCoords.length; i++) {
    const moveCoord = moveCoords[i];

    if (preFillTerrain) {
      await callTx(
        {
          ...txOptions,
          functionName: "computeTerrainObjectTypeIdWithSet",
          args: [moveCoord],
        },
        "fill"
      );

      const belowCoord = { x: moveCoord.x, y: moveCoord.y - 1, z: moveCoord.z };
      await callTx(
        {
          ...txOptions,
          functionName: "computeTerrainObjectTypeIdWithSet",
          args: [belowCoord],
        },
        "fill below"
      );
    }
  }

  await callTx({
    ...txOptions,
    functionName: "activatePlayer",
    args: [account.address],
  });

  await callTx(
    {
      ...txOptions,
      functionName: "move",
      args: [moveCoords],
    },
    "move " + moveCoords.length
  );
}
