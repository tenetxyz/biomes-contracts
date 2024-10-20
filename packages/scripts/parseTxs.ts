import { Hex, decodeFunctionData } from "viem";
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
    //   TxHash: "0xae07a549f1b91e168fa98d24176bcfa765697a728f6c8cf053bae79045e9630d",
    // },
  ];

  // Read the CSV file and push all rows to the array
  fs.createReadStream(csvFilePath)
    .pipe(csv())
    .on("data", (row) => {
      rows.push(row);
    })
    .on("end", async () => {
      console.log("CSV file successfully processed. Starting transaction processing...");

      // Now process each row serially using a for loop
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

            console.log("Function Name:", functionName);
            console.log("Arguments:", args);
            console.log("Gas Used:", calculateCalldataGasCost(transaction.input));
            if (functionName == "batchCallFrom") {
              for (const batchCallArgs of args[0]) {
                const callFromCallData = decodeFunctionData({ abi: IWorldAbi, data: batchCallArgs["callData"] });
                console.log("Call From Function Name:", callFromCallData.functionName);
                console.log("Call From Arguments:", callFromCallData.args);
              }
            }
          } catch (error) {
            console.error(`Error processing transaction ${TxHash}:`, error);
          }
        }
      }

      console.log("All transactions processed.");
      process.exit(0); // Exit after processing all rows
    })
    .on("error", (error) => {
      console.error("Error reading CSV file:", error);
      process.exit(1); // Exit with error
    });
}

main();
