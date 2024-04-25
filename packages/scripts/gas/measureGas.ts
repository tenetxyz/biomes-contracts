import { printMoveGasCosts } from "./moveGas";

async function measureGas() {
  const preFillTerrain = false;
  const preMoveCoords = [
    { x: 362, y: 17, z: -225 },
    { x: 361, y: 16, z: -225 },
    { x: 360, y: 16, z: -226 },
    { x: 359, y: 16, z: -225 },
    { x: 358, y: 16, z: -225 },
    { x: 357, y: 16, z: -225 },
  ];

  const moveCoords = [
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

  await printMoveGasCosts(preMoveCoords, moveCoords, preFillTerrain);

  process.exit(0);
}

measureGas();
