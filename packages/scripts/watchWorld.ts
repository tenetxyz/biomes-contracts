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

  process.exit(0);
}

main();
