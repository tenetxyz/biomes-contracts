import { Hex } from "viem";
import { setupNetwork } from "./setupNetwork";

async function main() {
  const { publicClient, worldAddress, IWorldAbi, account, txOptions, callTx } = await setupNetwork();

  await callTx({
    ...txOptions,
    functionName: "unregisterDelegation",
    args: ["0xC1e2405A4CFB42D17e6230c772284E6f99d66908"],
  });

  process.exit(0);
}

main();
