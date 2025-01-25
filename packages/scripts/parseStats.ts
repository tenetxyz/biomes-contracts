import { Worker } from "worker_threads";
import fs from "fs";
import path from "path";
import { formatEther, parseAbi } from "viem";
import { setupNetwork } from "./setupNetwork";
import os from "os";
import { replacer, reviver } from "./utils";

const wordlDeployer = "0x1f820052916970Ff09150b58F2f0Fb842C5a58be";

async function main() {
  const startTime = Date.now();

  // Setup initial configuration
  const { publicClient, worldAddress, allAbis, account, txOptions, callTx, fromBlock, indexerUrl } =
    await setupNetwork();

  const userNamesData = await fetch("https://biome1.biomes.aw/api/user/names").then((res) => res.json());
  const addressToName = userNamesData.addressToName;

  const query = [
    {
      address: worldAddress,
      query: 'SELECT "delegator", "delegatee", "delegationControlId" FROM world__UserDelegationCo;',
    },
  ];

  console.log("indexerUrl", indexerUrl);
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

  const stats = JSON.parse(fs.readFileSync("gen/stats.json", "utf8"), reviver);
  const allUserStats = stats.allUserStats;

  const startDate = new Date("2024-10-01T00:00:00.000Z");

  const functionNames: Set<string> = new Set();

  for (const user in allUserStats) {
    // if (allUserStats[user].numTxs < 50) continue;
    const txCounts = allUserStats[user].txCounts;
    // console.log("txCounts", txCounts);
    for (const fnName of txCounts.keys()) {
      functionNames.add(fnName);
    }

    const firstTxDate = new Date(allUserStats[user].firstTxDate);
  }

  const csvRows = [
    [
      "Address",
      "Username",
      "First Tx Date",
      "Last Tx Date",
      "Total # Txs",
      "Total Fees (wei)",
      "Total Fees (Eth)",
      "Avg Total Fees (wei)",
      "Avg Total Fees (Eth)",
      "Total L1 Fees (wei)",
      "Total L1 Fees (Eth)",
      "Total L2 Fees (wei)",
      "Total L2 Fees (Eth)",
      "Total Base Fees (wei)",
      "Total Base Fees (Eth)",
      "Total Priority Fees (wei)",
      "Total Priority Fees (Eth)",
    ],
  ];
  const fnNameArr = ["Address", "Username", ...[...functionNames]];
  const fnNameCsvRows = [fnNameArr.map((fn) => `# ${fn}`)];
  console.log("Processing users...");
  for (const user in allUserStats) {
    if (user.toLowerCase() === wordlDeployer.toLowerCase()) continue;

    const txCounts = allUserStats[user].txCounts;
    const firstTxDate = new Date(allUserStats[user].firstTxDate);
    const lastTxDate = new Date(allUserStats[user].lastTxDate);
    const delegator = delegations.get(user);
    const avgTotalFeesWei =
      allUserStats[user].numTxs > 0 ? allUserStats[user].totalFees / BigInt(allUserStats[user].numTxs) : 0n;
    // console.log(txCounts);
    const username = addressToName[user];
    csvRows.push([
      user,
      username,
      firstTxDate.toLocaleDateString(),
      lastTxDate.toLocaleDateString(),
      allUserStats[user].numTxs,
      allUserStats[user].totalFees,
      formatEther(allUserStats[user].totalFees),
      avgTotalFeesWei,
      formatEther(avgTotalFeesWei),
      allUserStats[user].totalL1Fees,
      formatEther(allUserStats[user].totalL1Fees),
      allUserStats[user].totalL2Fees,
      formatEther(allUserStats[user].totalL2Fees),
      allUserStats[user].totalBaseFees,
      formatEther(allUserStats[user].totalBaseFees),
      allUserStats[user].totalPriorityFees,
      formatEther(allUserStats[user].totalPriorityFees),
    ]);
    fnNameCsvRows.push([user, username, ...fnNameArr.map((fn) => txCounts.get(fn) ?? 0)]);
  }
  console.log("csvRows", csvRows.length);
  console.log("fnNameCsvRows", fnNameCsvRows.length);

  // write to file
  fs.writeFileSync("gen/userStats.csv", csvRows.map((row) => row.join(",")).join("\n"));
  fs.writeFileSync("gen/userStatsFn.csv", fnNameCsvRows.map((row) => row.join(",")).join("\n"));

  console.log("Finished!");
}

main().catch(console.error);
