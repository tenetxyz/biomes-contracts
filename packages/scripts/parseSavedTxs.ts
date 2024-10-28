import { Worker } from "worker_threads";
import fs from "fs";
import path from "path";
import { formatEther } from "viem";
import { setupNetwork } from "./setupNetwork";
import os from "os";

// Number of CPU cores to use (leave one core free for system processes)
const NUM_WORKERS = Math.max(1, os.cpus().length - 1);
const BATCH_SIZE = 100; // Number of files to process in each batch

async function createWorker(filesToProcess, IWorldAbi) {
  return new Promise((resolve, reject) => {
    const worker = new Worker("./workerCode.cjs");
    worker.on("message", resolve);
    worker.on("error", reject);
    worker.on("exit", (code) => {
      if (code !== 0) reject(new Error(`Worker stopped with exit code ${code}`));
    });

    worker.postMessage({
      filesToProcess,
      IWorldAbi,
    });
  });
}

async function main() {
  const startTime = Date.now();

  // Setup initial configuration
  const { publicClient, worldAddress, IWorldAbi, account, txOptions, callTx } = await setupNetwork();

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
      const result = await createWorker(batch, IWorldAbi);
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
  });

  const endTime = Date.now();

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

  console.log("Finished!");
}

main().catch(console.error);
