import { Hex, parseAbi } from "viem";
import { setupNetwork } from "./setupNetwork";
import { resourceToHex } from "@latticexyz/common";
import { storeEventsAbi } from "@latticexyz/store";
import prompts from "prompts";

export function isDefined<T>(argument: T | undefined): argument is T {
  return argument !== undefined;
}

async function main() {
  const { publicClient, worldAddress, IWorldAbi, account, txOptions, callTx } = await setupNetwork();

  const inventory = await publicClient.readContract({
    address: worldAddress as Hex,
    abi: IWorldAbi,
    functionName: "getInventory",
    args: ["0xE0ae70caBb529336e25FA7a1f036b77ad0089d2a"],
    account,
  });
  console.log("inventory:", inventory);

  const objectTypeIdAtCoord = await publicClient.readContract({
    address: worldAddress as Hex,
    abi: IWorldAbi,
    functionName: "getObjectTypeIdAtCoord",
    args: [{ x: -292, y: 30, z: -1312 }],
    account,
  });
  console.log("objectTypeIdAtCoord:", objectTypeIdAtCoord);

  // const emptyInitCallData = "0x0000000000000000000000000000000000000000000000000000000000000000";
  // const UNLIMITED_DELEGATION = resourceToHex({ type: "system", namespace: "", name: "unlimited" });

  // await callTx({
  //   ...txOptions,
  //   functionName: "registerDelegation",
  //   args: ["0xe0ae70cabb529336e25fa7a1f036b77ad0089d2a", UNLIMITED_DELEGATION, emptyInitCallData],
  // });

  const floraCoord = { x: 360, y: 16, z: -225 };
  const airCoord = { x: 360, y: 17, z: -225 };
  const sandCoord = { x: 305, y: 13, z: -251 };
  const treeCoord = { x: 323, y: 17, z: -272 };
  const oreCoord = { x: 195, y: 17, z: -276 };

  const objectTypeAtCoord = await publicClient.readContract({
    address: worldAddress as Hex,
    abi: IWorldAbi,
    functionName: "getTerrainObjectTypeId",
    args: [{ x: -320, y: 35, z: -1281 }],
    account,
  });
  console.log("Object Type:", objectTypeAtCoord);

  // const simGas = await publicClient.estimateContractGas({
  //   ...txOptions,
  //   functionName: "computeTerrainObjectTypeIdWithSet",
  //   args: [oreCoord],
  // });
  // console.log(simGas.toLocaleString());

  // await callTx({
  //   ...txOptions,
  //   functionName: "computeTerrainObjectTypeIdWithSet",
  //   args: [oreCoord],
  // });

  process.exit(0);
}

main();
