import { Hex } from "viem";
import { setupNetwork } from "./setupNetwork";

import fs from "fs";
import path from "path";
import { replacer } from "./utils";

async function loadTransactionHashes(inputFilePath: string): Promise<{
  transactions: Hex[];
  contractAddress: Hex;
  fromBlock: string;
  toBlock: string;
}> {
  const fileContent = await fs.promises.readFile(inputFilePath, "utf-8");
  return JSON.parse(fileContent);
}

async function saveDetailedTransactionsBatch(
  transactions: any[],
  contractAddress: Hex,
  fromBlock: string,
  toBlock: string,
  batchNumber: number,
) {
  const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
  const fileName = `detailed_txs_${contractAddress}_from${fromBlock}_to${toBlock}_batch${batchNumber}_${timestamp}.json`;

  // const data = {
  //   contractAddress,
  //   fromBlock,
  //   toBlock,
  //   totalTransactions: transactions.length,
  //   scanCompletedAt: new Date().toISOString(),
  //   transactions,
  // };

  try {
    const outputDir = path.join(process.cwd(), "gen");
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir);
    }

    const filePath = path.join(outputDir, fileName);

    const finalData =
      `{"contractAddress": "${contractAddress}", "fromBlock": "${fromBlock}", "toBlock": "${toBlock}", "totalTransactions": ${transactions.length}, ` +
      `"scanCompletedAt": "${new Date().toISOString()}", "transactions": [` +
      transactions.map((el) => JSON.stringify(el, replacer, 2)).join(",") +
      "]}";
    await fs.promises.writeFile(filePath, finalData);
    console.log(`Saved detailed transactions for batch ${batchNumber} to ${filePath}`);
  } catch (error) {
    console.error("Error saving to JSON:", error);
  }
}

async function main() {
  const { publicClient, fromBlock, worldAddress, IWorldAbi, account, txOptions, callTx } = await setupNetwork();

  try {
    // Get the input file path from command line arguments or use a default
    const inputFile = process.argv[2] || path.join(process.cwd(), "gen", "latest_transactions.json");
    console.log(`Reading from: ${inputFile}`);

    const { transactions: txHashes, contractAddress, fromBlock, toBlock } = await loadTransactionHashes(inputFile);
    console.log(`Processing ${txHashes.length} transactions...`);

    const batchSize = 50; // Adjust based on RPC rate limits

    // Process transactions in batches
    for (let i = 0; i < txHashes.length; i += batchSize) {
      const batch = txHashes.slice(i, i + batchSize);
      const batchNumber = Math.floor(i / batchSize) + 1;

      console.log(`Processing batch ${batchNumber} of ${Math.ceil(txHashes.length / batchSize)}`);

      const batchPromises = batch.map(async (hash) => {
        try {
          const [transaction, transactionReceipt] = await Promise.all([
            publicClient.getTransaction({ hash }),
            publicClient.getTransactionReceipt({ hash }),
          ]);

          // delete logs and logsBloom from transactionReceipt
          delete transactionReceipt.logs;
          delete transactionReceipt.logsBloom;

          return {
            hash,
            transaction,
            receipt: transactionReceipt,
          };
        } catch (error) {
          console.error(`Error processing transaction ${hash}:`, error);
          return {
            hash,
            error: error.message,
          };
        }
      });

      const batchResults = await Promise.all(batchPromises);

      // Save progress periodically
      await saveDetailedTransactionsBatch(batchResults, contractAddress, fromBlock, toBlock, batchNumber);

      // Add a small delay between batches to avoid rate limiting
      await new Promise((resolve) => setTimeout(resolve, 3000));
    }

    console.log("Processing completed!");
  } catch (error) {
    console.error("Error:", error);
  }
}

main();
