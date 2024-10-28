import { setupNetwork } from "./setupNetwork";
import fs from "fs";
import path from "path";
import { reviver } from "./utils";
import { formatEther } from "viem";

async function main() {
  const { publicClient, worldAddress, IWorldAbi, account, txOptions, callTx } = await setupNetwork();

  const dirPath = path.join(process.cwd(), "gen/server_gen");
  const files = fs.readdirSync(dirPath).filter((file) => file.startsWith("detailed_txs_"));

  let aggregatedFees = {
    baseFeeTotal: BigInt(0),
    l2FeeTotal: BigInt(0),
    l1FeeTotal: BigInt(0),
    totalFeeSum: BigInt(0),
  };

  const seenTxHashes = new Set();

  let numFilesProcessed = 0;
  for (const file of files) {
    const filePath = path.join(dirPath, file);
    const fileContent = await fs.promises.readFile(filePath, "utf-8");
    const { transactions } = JSON.parse(fileContent, reviver);

    for (const tx of transactions) {
      if (seenTxHashes.has(tx.hash)) {
        continue;
      }
      seenTxHashes.add(tx.hash);
      // console.log("Processing transaction", tx.hash);
      try {
        const baseFee =
          BigInt(tx.receipt.effectiveGasPrice) -
          (tx.transaction.maxPriorityFeePerGas ? BigInt(tx.transaction.maxPriorityFeePerGas) : 0n);
        const l2Fee = BigInt(tx.receipt.gasUsed) * BigInt(tx.receipt.effectiveGasPrice);
        const l1Fee = BigInt(tx.receipt.l1Fee);
        const totalFee = l2Fee + l1Fee;

        // console.log("Base fee:", formatEther(baseFee));
        // console.log("L2 fee:", formatEther(l2Fee));
        // console.log("L1 fee:", formatEther(l1Fee));
        // console.log("Total fee:", formatEther(totalFee));

        aggregatedFees.baseFeeTotal += baseFee;
        aggregatedFees.l2FeeTotal += l2Fee;
        aggregatedFees.l1FeeTotal += l1Fee;
        aggregatedFees.totalFeeSum += totalFee;
      } catch (error) {
        console.error(`Error calculating fees for transaction ${tx.hash}:`, error);
        console.log(tx);
      }
    }

    numFilesProcessed++;

    if (numFilesProcessed > 0 && numFilesProcessed % 100 === 0) {
      console.log("Progress:", numFilesProcessed / files.length, "files processed");
    }
  }

  console.log("Processed", seenTxHashes.size, "transactions");
  console.log("Aggregated fees:");
  console.log("Base fee total:", formatEther(aggregatedFees.baseFeeTotal));
  console.log("L2 fee total:", formatEther(aggregatedFees.l2FeeTotal));
  console.log("L1 fee total:", formatEther(aggregatedFees.l1FeeTotal));
  console.log("Total fee sum:", formatEther(aggregatedFees.totalFeeSum));
}

main();
