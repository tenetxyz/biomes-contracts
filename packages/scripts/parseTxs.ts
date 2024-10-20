import { Hex, decodeFunctionData, formatEther } from "viem";
import { setupNetwork } from "./setupNetwork";
import { resourceToHex } from "@latticexyz/common";
import { storeEventsAbi } from "@latticexyz/store";
import prompts from "prompts";
import fs from "fs";
import csv from "csv-parser";

function calculateCalldataGasCost(calldataHex: string): { gasCost: number; nonZeroBytes: number; zeroBytes: number } {
  // Remove '0x' prefix and convert to bytes
  const calldata = Buffer.from(calldataHex.slice(2), "hex");

  // Count non-zero and zero bytes
  let nonZeroBytes = 0;
  let zeroBytes = 0;

  for (const byte of calldata) {
    if (byte !== 0) {
      nonZeroBytes++;
    } else {
      zeroBytes++;
    }
  }

  // Calculate gas cost using the provided formula
  const gasCost = nonZeroBytes * 16 + zeroBytes * 4;

  return {
    gasCost,
    nonZeroBytes,
    zeroBytes,
  };
}

async function main() {
  const { publicClient, worldAddress, IWorldAbi, account, txOptions, callTx } = await setupNetwork();

  // Path to the CSV file
  const csvFilePath = "gen/transactions.csv";

  // Read and parse the CSV file
  const txHashes = [];

  // This will store all the rows to be processed serially
  const rows: any[] = [
    // {
    //   TxHash: "0xa63aa54d272467638f479f620befafbf7b39596ef045145a8ede445553d3a8fe",
    // },
  ];

  let totalL2Fee = 0n;
  let totalL1Fee = 0n;

  // Read the CSV file and push all rows to the array
  fs.createReadStream(csvFilePath)
    .pipe(csv())
    .on("data", (row) => {
      rows.push(row);
    })
    .on("end", async () => {
      console.log("CSV file successfully processed. Starting transaction processing...");

      // Now process each row serially using a for loop
      let numProcessed = 0;
      for (const row of rows) {
        const { TxHash } = row;

        if (TxHash) {
          console.log("Processing transaction:", TxHash);

          // Await each transaction processing sequentially
          try {
            const transaction = await publicClient.getTransaction({
              hash: TxHash,
            });
            const transactionReceipt = await publicClient.getTransactionReceipt({
              hash: TxHash,
            });
            // console.log("Transaction:", transaction);
            // console.log("Transaction Receipt:", transactionReceipt);

            const { functionName, args } = decodeFunctionData({
              abi: IWorldAbi,
              data: transaction.input,
            });

            const baseFee = transactionReceipt["effectiveGasPrice"] - transaction["maxPriorityFeePerGas"];
            const l2Fee = transactionReceipt["gasUsed"] * baseFee;
            const l1Fee = transactionReceipt["l1Fee"];
            const totalFee = l2Fee + transactionReceipt["l1Fee"];
            totalL2Fee += l2Fee;
            totalL1Fee += l1Fee;
            console.log("Total L2 Fee:", formatEther(l2Fee));
            console.log("Total L1 Fee:", formatEther(l1Fee));
            console.log("Total Fee:", formatEther(totalFee));
            console.log("% L1 Fee:", (Number(l1Fee) / Number(totalFee)) * 100);
            console.log("% L2 Fee:", (Number(l2Fee) / Number(totalFee)) * 100);

            console.log("Function Name:", functionName);
            // console.log("Arguments:", args);
            // console.log("Gas Used:", calculateCalldataGasCost(transaction.input));
            if (functionName == "batchCallFrom") {
              for (const batchCallArgs of args[0]) {
                const callFromCallData = decodeFunctionData({ abi: IWorldAbi, data: batchCallArgs["callData"] });
                console.log("Call From Function Name:", callFromCallData.functionName);
                console.log("Call From Arguments:", callFromCallData.args);
              }
            }
          } catch (error) {
            console.log(`Error processing transaction ${TxHash}:`, error);
          }
        }
        numProcessed++;
        if (numProcessed % 100 === 0) {
          console.log("Processed", numProcessed, "transactions.");
        }
      }

      const totalFee = totalL2Fee + totalL1Fee;
      console.log("Total L1 Fee:", formatEther(totalL1Fee));
      console.log("Total L2 Fee:", formatEther(totalL2Fee));
      console.log("Total Fee:", formatEther(totalFee));
      console.log("Total % L1 Fee:", (Number(totalL1Fee) / Number(totalFee)) * 100);
      console.log("Total % L2 Fee:", (Number(totalL2Fee) / Number(totalFee)) * 100);

      console.log("All transactions processed.");
      process.exit(0); // Exit after processing all rows
    })
    .on("error", (error) => {
      console.error("Error reading CSV file:", error);
      process.exit(1); // Exit with error
    });
}

main();
