import { Hex } from "viem";
import { setupNetwork } from "./setupNetwork";
import { ALL_SYSTEM_IDS, EMPTY_BYTES_32 } from "./constants";
import fs from "fs";
import prompts from "prompts";

async function main() {
  const { publicClient, worldAddress, IWorldAbi, account, txOptions, callTx } = await setupNetwork();

  const players = JSON.parse(fs.readFileSync("gen/allPlayers.json", "utf8"));

  console.log("Players to delete hooks for", players);
  // check if user added a --skip-confirm flag
  if (!process.argv.includes("--skip-confirm")) {
    const respose = await prompts({
      type: "confirm",
      name: "continue",
      message: "Are you sure you want to continue?",
    });
    if (!respose.continue) {
      process.exit(0);
    }
  }

  for (const player of players) {
    console.log(`Deleting all hooks for player ${player}`);
    for (const systemId of ALL_SYSTEM_IDS) {
      const systemHooks = await publicClient.readContract({
        address: worldAddress as Hex,
        abi: IWorldAbi,
        functionName: "getOptionalSystemHooks",
        args: [player, systemId, EMPTY_BYTES_32],
        account,
      });
      if (systemHooks.length === 0) {
        continue;
      }

      await callTx(
        {
          ...txOptions,
          functionName: "deleteAllUserHooks",
          args: [player, systemId, EMPTY_BYTES_32],
        },
        `Deleting all hooks for player ${player} and system ${systemId}`,
      );
    }
  }

  process.exit(0);
}

main();
