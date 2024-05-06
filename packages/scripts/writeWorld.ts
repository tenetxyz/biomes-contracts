import { Hex } from "viem";
import { setupNetwork } from "./setupNetwork";

async function main() {
  const { publicClient, worldAddress, IWorldAbi, account, txOptions, callTx } = await setupNetwork();

  await callTx({
    ...txOptions,
    functionName: "logoffStalePlayer",
    args: ["0xE0ae70caBb529336e25FA7a1f036b77ad0089d2a"],
  });

  process.exit(0);
}

main();
