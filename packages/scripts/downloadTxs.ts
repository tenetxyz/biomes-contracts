import { Hex, decodeFunctionData, formatEther } from "viem";
import { setupNetwork } from "./setupNetwork";
import { resourceToHex } from "@latticexyz/common";
import { storeEventsAbi } from "@latticexyz/store";
import prompts from "prompts";
import fs from "fs";
import csv from "csv-parser";

import { createPublicClient, http } from "viem";
import { mainnet } from "viem/chains";
import fs from "fs";
import path from "path";

// Configure the client
const client = createPublicClient({
  chain: mainnet,
  transport: http("YOUR_RPC_URL"),
});

async function saveToJson(
  transactions: Hex[],
  contractAddress: Hex,
  fromBlock: number,
  toBlock: number,
  suffix = "final",
) {
  const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
  const fileName = `txs_${contractAddress}_from${fromBlock}_to${toBlock}_${suffix}_${timestamp}.json`;

  const data = {
    contractAddress,
    fromBlock: fromBlock.toString(),
    toBlock: toBlock.toString(),
    totalTransactions: transactions.length,
    scanCompletedAt: new Date().toISOString(),
    transactions,
  };

  try {
    // Create 'output' directory if it doesn't exist
    const outputDir = path.join(process.cwd(), "gen");
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir);
    }

    const filePath = path.join(outputDir, fileName);
    await fs.promises.writeFile(filePath, JSON.stringify(data, null, 2));
    console.log(`Saved transactions to ${filePath}`);
  } catch (error) {
    console.error("Error saving to JSON:", error);
  }
}

async function main() {
  const { publicClient, fromBlock, worldAddress, IWorldAbi, account, txOptions, callTx } = await setupNetwork();

  // Read worlds JSON

  try {
    const currentBlock = Number(await publicClient.getBlockNumber());
    const transactions = [];
    const batchSize = 100; // Adjust based on RPC provider limits

    console.log(`Starting scan from block ${fromBlock} to ${currentBlock}`);

    // Process blocks in batches to avoid RPC timeout
    let numBlocksProcessed = 0;
    for (let i = fromBlock; i <= currentBlock; i += batchSize) {
      const toBlock = Math.min(i + batchSize - 1, currentBlock);

      try {
        const logs = await publicClient.getLogs({
          address: worldAddress,
          fromBlock: BigInt(i),
          toBlock: BigInt(toBlock),
        });
        // console.log(logs);

        // Get unique transaction hashes from the logs
        const txHashes = [...new Set(logs.map((log) => log.transactionHash))];
        transactions.push(...txHashes);

        console.log(`Processed blocks ${i} to ${toBlock}. Found ${txHashes.length} transactions in this batch.`);
        numBlocksProcessed++;

        // Save progress periodically
        if (numBlocksProcessed > 0 && numBlocksProcessed % 1000 === 0) {
          await saveToJson(transactions, contractAddress, fromBlock, i, "progress");
        }
      } catch (error) {
        console.error(`Error processing blocks ${i} to ${toBlock}:`, error);
      }
    }

    console.log("Total transactions found:", transactions.length);

    // Save final results
    await saveToJson(transactions, contractAddress, fromBlock);
  } catch (error) {
    console.error("Error:", error);
  }
}

main();
