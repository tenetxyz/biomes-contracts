import { Worker } from "worker_threads";
import fs from "fs";
import path from "path";
import { formatEther, parseAbi } from "viem";
import { setupNetwork } from "./setupNetwork";
import os from "os";
import { replacer } from "./utils";

async function main() {
  const startTime = Date.now();

  // Setup initial configuration
  const { publicClient, worldAddress, allAbis, account, txOptions, callTx, fromBlock, indexerUrl } =
    await setupNetwork();

  const query = [
    {
      address: worldAddress,
      query: 'SELECT "delegator", "delegatee", "delegationControlId" FROM world__UserDelegationCo;',
    },
  ];

  console.log("indexerUrl", indexerUrl);
  console.log("query", query);

  const delegations = new Map<string, string>();

  // fetch post request
  const response = await fetch(indexerUrl, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
    },
    body: JSON.stringify(query),
  });
  const content = await response.json();
  for (const row of content.result[0]) {
    delegations.set(row[0].toLowerCase(), row[1].toLowerCase());
    delegations.set(row[1].toLowerCase(), row[0].toLowerCase());
  }

  const stats = JSON.parse(fs.readFileSync("gen/stats.json", "utf8"));
  const allUserStats = stats.allUserStats;

  const SUB_NFT_ADDRESS = "0xE0aC150d02e4a9808403F94a289bcEc20d30A3fB";

  const startDate = new Date("2024-10-01T00:00:00.000Z");

  const users: Set<string> = new Set();
  for (const user in allUserStats) {
    if (allUserStats[user].numTxs < 50) continue;

    const firstTxDate = new Date(allUserStats[user].firstTxDate);
    if (firstTxDate >= startDate) {
      const delegator = delegations.get(user);
      if (delegator) {
        users.add(delegator);
      } else {
        users.add(user);
      }
    }
  }
  console.log("users", users);
  console.log("numUsers", users.size);

  let numUsersWithSubNFT = 0;
  let processedUsers = 0;
  // Process users in batches of 100
  const batchSize = 100;
  const userArray = Array.from(users);

  for (let i = 0; i < userArray.length; i += batchSize) {
    const batch = userArray.slice(i, i + batchSize);
    const balances = await Promise.all(
      batch.map((user) =>
        publicClient.readContract({
          address: SUB_NFT_ADDRESS,
          abi: parseAbi(["function balanceOf(address account) external view returns (uint256)"]),
          functionName: "balanceOf",
          args: [user as `0x${string}`],
        }),
      ),
    );

    numUsersWithSubNFT += balances.filter((balance) => balance > 0).length;
    processedUsers += batch.length;
    console.log(`Processed ${processedUsers} users`);
  }
  console.log("numUsersWithSubNFT", numUsersWithSubNFT);

  console.log("Finished!");
}

main().catch(console.error);
