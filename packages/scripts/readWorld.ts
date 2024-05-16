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

  const fromBlock = 1769929n;
  const toBlock = 1769937n;

  publicClient.watchContractEvent({
    address: "0x93fc6fc185aaDaA98DcF85D1F05D47109218E061",
    abi: parseAbi(["event GameNotif(address player, string message)"]),
    eventName: "GameNotif",
    fromBlock: fromBlock,
    onLogs: (logs) => console.log("event", logs),
  });

  const logs = await publicClient.getLogs({
    address: "0x93fc6fc185aaDaA98DcF85D1F05D47109218E061",
    events: parseAbi(["event GameNotif(address player, string message)"]),
    fromBlock,
    toBlock,
    strict: true,
  });
  console.log("logs", logs);
  // console.log("block range:", fromBlock, toBlock);
  // console.log("logs", logs.length);
  // const blockNumbers = Array.from(new Set(logs.map((log) => log.blockNumber)));
  // console.log("blockNumbers", blockNumbers);

  // wait for user input
  const respose = await prompts({
    type: "confirm",
    name: "continue",
    message: "Are you sure you want to continue?",
  });
  if (!respose.continue) {
    process.exit(0);
  }

  // const groupedBlocks = blockNumbers
  //   .map((blockNumber) => {
  //     const blockLogs = logs.filter((log) => log.blockNumber === blockNumber);
  //     if (!blockLogs.length) return;
  //     blockLogs.sort((a, b) => (a.logIndex < b.logIndex ? -1 : a.logIndex > b.logIndex ? 1 : 0));

  //     if (!blockLogs.length) return;

  //     return {
  //       blockNumber,
  //       logs: blockLogs,
  //     };
  //   })
  //   .filter(isDefined);
  // const gBlockNumbers = Array.from(new Set(groupedBlocks.map((gb) => gb.blockNumber)));
  // console.log("groupedBlocks", gBlockNumbers);

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
