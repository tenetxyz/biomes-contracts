import { Worker } from "worker_threads";
import fs from "fs";
import path from "path";
import { formatEther, parseAbi } from "viem";
import { setupNetwork } from "./setupNetwork";
import os from "os";
import { replacer, reviver } from "./utils";

const worldDeployer = "0x1f820052916970Ff09150b58F2f0Fb842C5a58be";

async function main() {
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
  const delegatorToDelegatee = new Map<string, string>();
  const delegateeToDelegator = new Map<string, string>();

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
    delegatorToDelegatee.set(row[0].toLowerCase(), row[1].toLowerCase());
    delegateeToDelegator.set(row[1].toLowerCase(), row[0].toLowerCase());
  }

  const stats = JSON.parse(fs.readFileSync("gen/stats.json", "utf8"), reviver);
  const allUserStats = stats.allUserStats;

  const startDate = new Date("2024-10-01T00:00:00.000Z");

  const functionNames: Set<string> = new Set();

  for (const user in allUserStats) {
    // if (allUserStats[user].numTxs < 50) continue;
    const txCounts = allUserStats[user].txCounts;
    for (const fnName of txCounts.keys()) {
      functionNames.add(fnName);
    }
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
  const processedUsers: Set<string> = new Set();
  for (const user in allUserStats) {
    if (user.toLowerCase() === worldDeployer.toLowerCase()) continue;
    if (processedUsers.has(user.toLowerCase())) continue;
    processedUsers.add(user.toLowerCase());

    let txCounts = allUserStats[user].txCounts;
    let firstTxDate = allUserStats[user].firstTxDate ? new Date(allUserStats[user].firstTxDate) : null;
    let lastTxDate = allUserStats[user].lastTxDate ? new Date(allUserStats[user].lastTxDate) : null;
    let numTxs = allUserStats[user].numTxs;
    let totalFees = allUserStats[user].totalFees;
    let totalL1Fees = allUserStats[user].totalL1Fees;
    let totalL2Fees = allUserStats[user].totalL2Fees;
    let totalBaseFees = allUserStats[user].totalBaseFees;
    let totalPriorityFees = allUserStats[user].totalPriorityFees;

    let delegator = delegateeToDelegator.get(user);
    if (delegator) {
      processedUsers.add(delegator.toLowerCase());
      const delegatorStats = allUserStats[delegator];
      if (delegatorStats !== undefined) {
        numTxs += delegatorStats.numTxs;
        totalFees += delegatorStats.totalFees;
        totalL1Fees += delegatorStats.totalL1Fees;
        totalL2Fees += delegatorStats.totalL2Fees;
        totalBaseFees += delegatorStats.totalBaseFees;
        totalPriorityFees += delegatorStats.totalPriorityFees;

        if (
          firstTxDate === null ||
          (delegatorStats.firstTxDate !== null && new Date(delegatorStats.firstTxDate) < firstTxDate)
        ) {
          firstTxDate = new Date(delegatorStats.firstTxDate);
        }
        if (
          lastTxDate === null ||
          (delegatorStats.lastTxDate !== null && new Date(delegatorStats.lastTxDate) > lastTxDate)
        ) {
          lastTxDate = new Date(delegatorStats.lastTxDate);
        }
      }
    }
    let delegatee = delegatorToDelegatee.get(user);
    if (delegatee) {
      processedUsers.add(delegatee.toLowerCase());
      const delegateeStats = allUserStats[delegatee];
      if (delegateeStats !== undefined) {
        numTxs += delegateeStats.numTxs;
        totalFees += delegateeStats.totalFees;
        totalL1Fees += delegateeStats.totalL1Fees;
        totalL2Fees += delegateeStats.totalL2Fees;
        totalBaseFees += delegateeStats.totalBaseFees;
        totalPriorityFees += delegateeStats.totalPriorityFees;

        if (
          firstTxDate === null ||
          (delegateeStats.firstTxDate !== null && new Date(delegateeStats.firstTxDate) < firstTxDate)
        ) {
          firstTxDate = new Date(delegateeStats.firstTxDate);
        }
        if (
          lastTxDate === null ||
          (delegateeStats.lastTxDate !== null && new Date(delegateeStats.lastTxDate) > lastTxDate)
        ) {
          lastTxDate = new Date(delegateeStats.lastTxDate);
        }
      }
    }
    if (numTxs === 0) {
      continue;
    }

    let userAddress = delegator ? delegator : user;
    if (firstTxDate === null) {
      throw new Error("firstTxDate is null for user " + user);
    }
    if (lastTxDate === null) {
      throw new Error("lastTxDate is null for user " + user);
    }

    const avgTotalFeesWei = numTxs > 0 ? totalFees / BigInt(numTxs) : 0n;
    // console.log(txCounts);
    const username = addressToName[userAddress];
    csvRows.push([
      userAddress,
      username,
      firstTxDate.toLocaleDateString(),
      lastTxDate.toLocaleDateString(),
      numTxs,
      totalFees,
      formatEther(totalFees),
      avgTotalFeesWei,
      formatEther(avgTotalFeesWei),
      totalL1Fees,
      formatEther(totalL1Fees),
      totalL2Fees,
      formatEther(totalL2Fees),
      totalBaseFees,
      formatEther(totalBaseFees),
      totalPriorityFees,
      formatEther(totalPriorityFees),
    ]);
    fnNameCsvRows.push([userAddress, username, ...fnNameArr.map((fn) => txCounts.get(fn) ?? 0)]);
  }
  console.log("csvRows", csvRows.length);
  console.log("fnNameCsvRows", fnNameCsvRows.length);

  // write to file
  fs.writeFileSync("gen/userStats.csv", csvRows.map((row) => row.join(",")).join("\n"));
  fs.writeFileSync("gen/userStatsFn.csv", fnNameCsvRows.map((row) => row.join(",")).join("\n"));

  console.log("Finished!");
}

main().catch(console.error);
