import { SPAWN_GROUND_Y, SPAWN_LOW_X, SPAWN_LOW_Z } from "../constants";
import { setupNetwork } from "../setupNetwork";

export async function setupGasTest(spawnAgent: boolean = true) {
  const setupNetorkData = await setupNetwork();

  const spawnCoord = {
    x: SPAWN_LOW_X,
    y: SPAWN_GROUND_Y + 1,
    z: SPAWN_LOW_Z,
  };

  if (spawnAgent) {
    await setupNetorkData.callTx({
      ...setupNetorkData.txOptions,
      functionName: "spawnPlayer",
      args: [spawnCoord],
    });
  }

  return {
    ...setupNetorkData,
    spawnCoord,
  };
}
