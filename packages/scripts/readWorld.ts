import { Hex } from "viem";
import { setupNetwork } from "./setupNetwork";

async function main() {
  const { publicClient, worldAddress, IWorldAbi, account, txOptions, callTx } = await setupNetwork();

  const floraCoord = { x: 360, y: 16, z: -225 };
  const airCoord = { x: 360, y: 17, z: -225 };
  const sandCoord = { x: 305, y: 13, z: -251 };
  const treeCoord = { x: 323, y: 17, z: -272 };
  const oreCoord = { x: 195, y: 17, z: -276 };

  const objectTypeAtCoord = await publicClient.readContract({
    address: worldAddress as Hex,
    abi: IWorldAbi,
    functionName: "getCachedTerrainObjectTypeId",
    args: [oreCoord],
    account,
  });
  console.log("Object Type:", objectTypeAtCoord);

  const simGas = await publicClient.estimateContractGas({
    ...txOptions,
    functionName: "computeTerrainObjectTypeIdWithSet",
    args: [oreCoord],
  });
  console.log(simGas.toLocaleString());

  await callTx({
    ...txOptions,
    functionName: "computeTerrainObjectTypeIdWithSet",
    args: [oreCoord],
  });

  process.exit(0);
}

main();
