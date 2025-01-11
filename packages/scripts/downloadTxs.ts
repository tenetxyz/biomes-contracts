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
): boolean {
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

  // filter out nulls
  const filteredTransactions = transactions.filter((el) => el !== null);
  if (filteredTransactions.length === 0) {
    console.log(`No transactions to save for batch ${batchNumber}`);
    return false;
  }

  try {
    const outputDir = path.join(process.cwd(), "gen");
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir);
    }

    const filePath = path.join(outputDir, fileName);

    const finalData =
      `{"contractAddress": "${contractAddress}", "fromBlock": "${fromBlock}", "toBlock": "${toBlock}", "totalTransactions": ${filteredTransactions.length}, ` +
      `"scanCompletedAt": "${new Date().toISOString()}", "transactions": [` +
      filteredTransactions.map((el) => JSON.stringify(el, replacer, 2)).join(",") +
      "]}";
    await fs.promises.writeFile(filePath, finalData);
    console.log(`Saved detailed transactions for batch ${batchNumber} to ${filePath}`);
  } catch (error) {
    console.error("Error saving to JSON:", error);
  }

  return true;
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

    const proccessedHashes = new Set();

    // Get list of files to process
    const dirPath = path.join(process.cwd(), "gen/");
    const files = fs
      .readdirSync(dirPath)
      .filter((file) => file.startsWith(`detailed_txs_${contractAddress}_from${fromBlock}_to${toBlock}_batch`))
      .map((file) => path.join(dirPath, file));

    for (const file of files) {
      const { transactions } = JSON.parse(fs.readFileSync(file, "utf-8"));
      for (const transaction of transactions) {
        proccessedHashes.add(transaction.hash.toLowerCase());
      }
    }

    console.log(`Processed ${proccessedHashes.size} hashes already`);

    // Process transactions in batches
    for (let i = 0; i < txHashes.length; i += batchSize) {
      const batch = txHashes.slice(i, i + batchSize);
      const batchNumber = Math.floor(i / batchSize) + 1;

      console.log(`Processing batch ${batchNumber} of ${Math.ceil(txHashes.length / batchSize)}`);

      const batchPromises = batch.map(async (hash) => {
        if (proccessedHashes.has(hash.toLowerCase())) {
          console.log(`Skipping transaction ${hash} as it has already been processed`);
          return null;
        }

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
          throw Error("Error processing blocks");
        }
      });

      const batchResults = await Promise.all(batchPromises);

      // Save progress periodically
      const saved = await saveDetailedTransactionsBatch(batchResults, contractAddress, fromBlock, toBlock, batchNumber);
      if (!saved) {
        continue;
      }

      // Add a small delay between batches to avoid rate limiting
      await new Promise((resolve) => setTimeout(resolve, 3000));
    }

    console.log("Processing completed!");
  } catch (error) {
    console.error("Error:", error);
    throw Error("Error processing blocks");
  }
}

main();
