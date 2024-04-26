import { GRASS_OBJECT_TYPE_ID, SPAWN_GROUND_Y, SPAWN_LOW_X, SPAWN_LOW_Z } from "../constants";
import { setupNetwork } from "../setupNetwork";
import { printBuildMineGasCosts } from "./buildMineGas";
import { printMoveGasCosts } from "./moveGas";
import { printSpawnCosts } from "./spawnGas";

async function measureGas() {
  const setupNetworkData = await setupNetwork();
  const { txOptions, callTx } = setupNetworkData;
  const preFillTerrain = true;

  const spawnCoord = {
    x: SPAWN_LOW_X,
    y: SPAWN_GROUND_Y + 1,
    z: SPAWN_LOW_Z,
  };

  await printSpawnCosts(setupNetworkData, spawnCoord, preFillTerrain);

  const preMoveCoords = [
    { x: 362, y: 17, z: -225 },
    { x: 361, y: 16, z: -225 },
    { x: 360, y: 16, z: -226 },
    { x: 359, y: 16, z: -225 },
    { x: 358, y: 16, z: -225 },
    { x: 357, y: 16, z: -225 },
  ];

  if (preMoveCoords.length > 0) {
    await callTx(
      {
        ...txOptions,
        functionName: "move",
        args: [preMoveCoords],
      },
      "pre move " + preMoveCoords.length
    );
  }

  const mineCoord = { x: 357, y: 15, z: -226 };
  const buildObjectType = GRASS_OBJECT_TYPE_ID;
  const buildCoord = { x: 357, y: 16, z: -227 };

  await printBuildMineGasCosts(setupNetworkData, mineCoord, buildCoord, buildObjectType, preFillTerrain);

  const tenMoveCoords = [
    { x: 357, y: 16, z: -224 },
    { x: 357, y: 16, z: -223 },
    { x: 357, y: 16, z: -222 },
    { x: 357, y: 16, z: -221 },
    { x: 357, y: 16, z: -220 },
    { x: 357, y: 16, z: -219 },
    { x: 357, y: 16, z: -218 },
    { x: 357, y: 16, z: -217 },
    { x: 357, y: 16, z: -216 },
    { x: 357, y: 16, z: -215 },
  ];

  const fiftyMoveCoords = [
    { x: 357, y: 16, z: -224 },
    { x: 357, y: 16, z: -223 },
    { x: 357, y: 16, z: -222 },
    { x: 357, y: 16, z: -221 },
    { x: 357, y: 16, z: -220 },
    { x: 357, y: 16, z: -219 },
    { x: 357, y: 16, z: -218 },
    { x: 357, y: 16, z: -217 },
    { x: 357, y: 16, z: -216 },
    { x: 357, y: 16, z: -215 },
    { x: 357, y: 16, z: -214 },
    { x: 357, y: 16, z: -213 },
    { x: 357, y: 16, z: -212 },
    { x: 357, y: 16, z: -211 },
    { x: 357, y: 16, z: -210 },
    { x: 357, y: 16, z: -209 },
    { x: 357, y: 16, z: -208 },
    { x: 357, y: 16, z: -207 },
    { x: 357, y: 16, z: -206 },
    { x: 357, y: 16, z: -205 },
    { x: 357, y: 16, z: -204 },
    { x: 357, y: 16, z: -203 },
    { x: 357, y: 16, z: -202 },
    { x: 357, y: 16, z: -201 },
    { x: 357, y: 16, z: -200 },
    { x: 357, y: 16, z: -199 },
    { x: 357, y: 16, z: -198 },
    { x: 357, y: 16, z: -197 },
    { x: 357, y: 16, z: -196 },
    { x: 357, y: 16, z: -195 },
    { x: 357, y: 16, z: -194 },
    { x: 356, y: 15, z: -193 },
    { x: 356, y: 15, z: -192 },
    { x: 357, y: 15, z: -191 },
    { x: 357, y: 15, z: -190 },
    { x: 357, y: 15, z: -189 },
    { x: 357, y: 15, z: -188 },
    { x: 357, y: 15, z: -187 },
    { x: 357, y: 15, z: -186 },
    { x: 357, y: 15, z: -185 },
    { x: 357, y: 15, z: -184 },
    { x: 357, y: 15, z: -183 },
    { x: 357, y: 15, z: -182 },
    { x: 357, y: 15, z: -181 },
    { x: 357, y: 15, z: -180 },
    { x: 356, y: 14, z: -179 },
    { x: 357, y: 14, z: -178 },
    { x: 357, y: 14, z: -177 },
    { x: 357, y: 14, z: -176 },
    { x: 357, y: 14, z: -175 },
  ];

  await printMoveGasCosts(setupNetworkData, fiftyMoveCoords, preFillTerrain);

  process.exit(0);
}

measureGas();
