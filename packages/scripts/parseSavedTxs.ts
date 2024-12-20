import { Worker } from "worker_threads";
import fs from "fs";
import path from "path";
import { formatEther } from "viem";
import { setupNetwork } from "./setupNetwork";
import os from "os";
import { replacer } from "./utils";

// Number of CPU cores to use (leave one core free for system processes)
const NUM_WORKERS = Math.max(1, os.cpus().length - 1);
const BATCH_SIZE = 100; // Number of files to process in each batch

async function createWorker(allWork) {
  return new Promise((resolve, reject) => {
    const worker = new Worker("./workerCode.cjs");
    worker.on("message", resolve);
    worker.on("error", reject);
    worker.on("exit", (code) => {
      if (code !== 0) reject(new Error(`Worker stopped with exit code ${code}`));
    });

    worker.postMessage(allWork);
  });
}

async function main() {
  const startTime = Date.now();

  // Setup initial configuration
  const { publicClient, worldAddress, IWorldAbi, account, txOptions, callTx, fromBlock } = await setupNetwork();

  const referenceStartBlock = BigInt(fromBlock);
  const block = await publicClient.getBlock({
    blockNumber: referenceStartBlock,
  });
  const referenceStartTimestamp = block.timestamp;
  console.log(`Block ${fromBlock} timestamp: ${referenceStartTimestamp}`);

  // Get list of files to process
  const dirPath = path.join(process.cwd(), "gen/server_gen");
  const files = fs
    .readdirSync(dirPath)
    .filter((file) => file.startsWith("detailed_txs_"))
    .map((file) => path.join(dirPath, file));

  // Split files into batches for each worker
  const batchedFiles = [];
  for (let i = 0; i < files.length; i += BATCH_SIZE) {
    batchedFiles.push(files.slice(i, i + BATCH_SIZE));
  }

  console.log(`Processing ${files.length} files using ${NUM_WORKERS} workers...`);

  // Create worker pool and process batches
  const workers = new Array(NUM_WORKERS).fill(null).map(() => []);
  let currentWorker = 0;

  // Distribute batches across workers
  batchedFiles.forEach((batch) => {
    workers[currentWorker].push(batch);
    currentWorker = (currentWorker + 1) % NUM_WORKERS;
  });

  // Process all batches in parallel
  const workerPromises = workers.map(async (workerBatches, index) => {
    if (workerBatches.length === 0) return null;

    const results = [];
    for (const batch of workerBatches) {
      const result = await createWorker({
        filesToProcess: batch,
        IWorldAbi,
        referenceStartBlock: referenceStartBlock,
        referenceStartTimestamp: referenceStartTimestamp,
      });
      if (result.error) {
        throw new Error(`Worker ${index} error: ${result.error}`);
      }
      results.push(result);
    }
    return results;
  });

  // Wait for all workers to complete and aggregate results
  const workerResults = (await Promise.all(workerPromises)).filter(Boolean);

  // Combine results from all workers
  const finalResults = {
    baseFeeTotal: BigInt(0),
    l2FeeTotal: BigInt(0),
    l1FeeTotal: BigInt(0),
    totalFeeSum: BigInt(0),
  };
  const finalTxCounts = new Map();
  const finalDailyStats = new Map();

  let totalTransactions = 0;
  let finalEarliestFromBlock = Infinity;
  let finalLatestToBlock = 0;

  workerResults.flat().forEach((result) => {
    finalResults.baseFeeTotal += result.aggregatedFees.baseFeeTotal;
    finalResults.l2FeeTotal += result.aggregatedFees.l2FeeTotal;
    finalResults.l1FeeTotal += result.aggregatedFees.l1FeeTotal;
    finalResults.totalFeeSum += result.aggregatedFees.totalFeeSum;
    totalTransactions += result.numTransactions;
    // iterate oer result.txCounts map
    for (const [txType, count] of result.txCounts.entries()) {
      if (!finalTxCounts.has(txType)) {
        finalTxCounts.set(txType, 0);
      }
      finalTxCounts.set(txType, finalTxCounts.get(txType) + count);
    }

    finalEarliestFromBlock = Math.min(finalEarliestFromBlock, result.fromBlock);
    finalLatestToBlock = Math.max(finalLatestToBlock, result.toBlock);

    // dailyStat = { txCount: 0, fees: BigInt(0), users: new Set() };

    for (const [date, resultDailyStat] of result.dailyStats.entries()) {
      let dailyStat = finalDailyStats.get(date);
      if (dailyStat === undefined) {
        dailyStat = { txCount: 0, fees: BigInt(0), users: new Set() };
      }
      dailyStat.txCount += resultDailyStat.txCount;
      dailyStat.fees += resultDailyStat.fees;
      for (const user of resultDailyStat.users) {
        dailyStat.users.add(user);
      }
      finalDailyStats.set(date, dailyStat);
    }
  });

  // Print results
  console.log("\nProcessing completed!");
  // console.log(`Time taken: ${((endTime - startTime) / 1000).toFixed(2)} seconds`);
  console.log(`From block: ${finalEarliestFromBlock}`);
  console.log(`To block: ${finalLatestToBlock}`);
  console.log(`Processed ${totalTransactions} unique transactions`);
  console.log("\nAggregated fees:");
  console.log("Base fee total:", formatEther(finalResults.baseFeeTotal));
  console.log("L2 fee total:", formatEther(finalResults.l2FeeTotal));
  console.log("L1 fee total:", formatEther(finalResults.l1FeeTotal));
  console.log("Total fee sum:", formatEther(finalResults.totalFeeSum));
  console.log("\nTransaction counts:");
  for (const [txType, count] of finalTxCounts.entries()) {
    console.log(`${txType}: ${count}`);
  }

  // console.log("\nDaily Statistics:");
  // for (const [date, dailyStat] of finalDailyStats.entries()) {
  //   console.log(`${date}:`);
  //   console.log(`  Transactions: ${dailyStat.txCount}`);
  //   console.log(`  Fees: ${formatEther(dailyStat.fees)}`);
  //   console.log(`  Unique users: ${dailyStat.users.size}`);
  // }

  // Write these stats to a file
  const stats = {
    fromBlock: finalEarliestFromBlock,
    toBlock: finalLatestToBlock,
    totalTransactions,
    aggregatedFees: finalResults,
    txCounts: Object.fromEntries(finalTxCounts),
    dailyStats: Object.fromEntries(
      Array.from(finalDailyStats.entries()).map(([date, dailyStat]) => {
        return [date, { ...dailyStat, users: Array.from(dailyStat.users) }];
      }),
    ),
  };
  fs.writeFileSync("gen/stats.json", JSON.stringify(stats, replacer, 2));

  console.log("Finished!");
}

main().catch(console.error);
