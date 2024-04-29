import { Hex } from "viem";
import { setupNetwork } from "./setupNetwork";

async function main() {
  const { publicClient, worldAddress, IWorldAbi, account, txOptions, callTx } = await setupNetwork();

  await callTx({
    ...txOptions,
    functionName: "unregisterDelegation",
    args: ["0xD50ba6a632Bc7C07e36A8004847007bEf245a69f"],
  });

  process.exit(0);
}

main();
