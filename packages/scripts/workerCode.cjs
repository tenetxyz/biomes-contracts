const { parentPort, workerData } = require("worker_threads");
const fs = require("fs");
const path = require("path");
const { decodeFunctionData } = require("viem");

const { replacer, reviver } = require("./utils");

async function processFiles({ filesToProcess, IWorldAbi, referenceStartBlock, referenceStartTimestamp }) {
  const aggregatedFees = {
    baseFeeTotal: BigInt(0),
    priorityFeeTotal: BigInt(0),
    l2FeeTotal: BigInt(0),
    l1FeeTotal: BigInt(0),
    totalFeeSum: BigInt(0),
  };

  const seenTxHashes = new Set();
  const txCounts = new Map();
  const dailyStats = new Map();
  let earliestFromBlock = Infinity;
  let latestToBlock = 0;
  const perUserStats = new Map();

  for (const filePath of filesToProcess) {
    const fileContent = await fs.promises.readFile(filePath, "utf-8");
    const { fromBlock, toBlock, transactions } = JSON.parse(fileContent, reviver);

    try {
      earliestFromBlock = Math.min(earliestFromBlock, fromBlock);
      latestToBlock = Math.max(latestToBlock, toBlock);
    } catch (e) {
      console.error("Error updating earliestFromBlock and latestToBlock", e);
    }

    for (const tx of transactions) {
      if (seenTxHashes.has(tx.hash)) continue;
      seenTxHashes.add(tx.hash);
      let perUserStat = perUserStats.get(tx.receipt.from.toLowerCase());
      if (perUserStat === undefined) {
        perUserStat = {
          txCounts: new Map(),
          numActions: 0,
          numTxs: 0,
          totalL2Fees: BigInt(0),
          totalL1Fees: BigInt(0),
          totalBaseFees: BigInt(0),
          totalPriorityFees: BigInt(0),
          totalFees: BigInt(0),
          firstTxDate: null,
          lastTxDate: null,
        };
      }

      let totalFee = 0n;
      try {
        const priorityFee = tx.transaction.maxPriorityFeePerGas ? BigInt(tx.transaction.maxPriorityFeePerGas) : 0n;
        const baseFee = BigInt(tx.receipt.effectiveGasPrice) - priorityFee;
        const l2Fee = BigInt(tx.receipt.gasUsed) * BigInt(tx.receipt.effectiveGasPrice);
        const l1Fee = BigInt(tx.receipt.l1Fee);
        totalFee = l2Fee + l1Fee;

        aggregatedFees.baseFeeTotal += baseFee;
        aggregatedFees.priorityFeeTotal += priorityFee;
        aggregatedFees.l2FeeTotal += l2Fee;
        aggregatedFees.l1FeeTotal += l1Fee;
        aggregatedFees.totalFeeSum += totalFee;

        perUserStat.totalBaseFees += baseFee;
        perUserStat.totalL2Fees += l2Fee;
        perUserStat.totalL1Fees += l1Fee;
        perUserStat.totalFees += totalFee;
        perUserStat.totalPriorityFees += priorityFee;
      } catch (error) {
        console.error(`Error calculating fees for transaction ${tx.hash}:`, error);
      }

      let numTxs = 0;
      try {
        const { functionName, args } = decodeFunctionData({
          abi: IWorldAbi,
          data: tx.transaction.input,
        });
        if (functionName == "batchCallFrom") {
          for (const batchCallArgs of args[0]) {
            const callFromCallData = decodeFunctionData({ abi: IWorldAbi, data: batchCallArgs["callData"] });
            // console.log("Call From Function Name:", callFromCallData.functionName);
            // console.log("Call From Arguments:", callFromCallData.args);
            const newCount = txCounts.get(callFromCallData.functionName) || 0;
            txCounts.set(callFromCallData.functionName, newCount + 1);
            numTxs++;

            const perUserCount = perUserStat.txCounts.get(callFromCallData.functionName) || 0;
            perUserStat.txCounts.set(callFromCallData.functionName, perUserCount + 1);
            perUserStat.numActions++;
          }
        } else if (functionName == "callFrom") {
          const callFromCallData = decodeFunctionData({ abi: IWorldAbi, data: args[2] });
          // console.log("Call From Function Name:", callFromCallData.functionName);
          // console.log("Call From Arguments:", callFromCallData.args);
          const newCount = txCounts.get(callFromCallData.functionName) || 0;
          txCounts.set(callFromCallData.functionName, newCount + 1);
          numTxs++;

          const perUserCount = perUserStat.txCounts.get(callFromCallData.functionName) || 0;
          perUserStat.txCounts.set(callFromCallData.functionName, perUserCount + 1);
          perUserStat.numActions++;
        } else if (functionName == "batchCall") {
          for (const batchCallArgs of args[0]) {
            const callFromCallData = decodeFunctionData({ abi: IWorldAbi, data: batchCallArgs["callData"] });
            // console.log("Call From Function Name:", callFromCallData.functionName);
            // console.log("Call From Arguments:", callFromCallData.args);
            const newCount = txCounts.get(callFromCallData.functionName) || 0;
            txCounts.set(callFromCallData.functionName, newCount + 1);
            numTxs++;

            const perUserCount = perUserStat.txCounts.get(callFromCallData.functionName) || 0;
            perUserStat.txCounts.set(callFromCallData.functionName, perUserCount + 1);
            perUserStat.numActions++;
          }
        } else {
          const newCount = txCounts.get(functionName) || 0;
          txCounts.set(functionName, newCount + 1);
          numTxs++;

          const perUserCount = perUserStat.txCounts.get(functionName) || 0;
          perUserStat.txCounts.set(functionName, perUserCount + 1);
          perUserStat.numActions++;
        }
        perUserStat.numTxs++;

        try {
          const blockNumber = BigInt(tx.receipt.blockNumber);
          const blocksSinceReference = blockNumber - referenceStartBlock;
          const estimatedBlockTimestamp = referenceStartTimestamp + blocksSinceReference * 2n;
          const txDate = new Date(Number(estimatedBlockTimestamp * 1000n));
          const txDateStr = txDate.toISOString().slice(0, 10);
          let dailyStat = dailyStats.get(txDateStr);
          if (dailyStat === undefined) {
            dailyStat = { txCount: 0, fees: BigInt(0), users: new Set() };
          }
          dailyStat.txCount += numTxs;
          dailyStat.fees += totalFee;
          dailyStat.users.add(tx.receipt.from);

          if (perUserStat.firstTxDate === null || txDate < perUserStat.firstTxDate) {
            perUserStat.firstTxDate = txDate;
          }
          if (perUserStat.lastTxDate === null || txDate > perUserStat.lastTxDate) {
            perUserStat.lastTxDate = txDate;
          }

          dailyStats.set(txDateStr, dailyStat);
        } catch (e) {
          console.error("Error updating daily stats", e);
        }

        perUserStats.set(tx.receipt.from.toLowerCase(), perUserStat);
      } catch (e) {
        // console.log("Error decoding function data", e);
      }
    }
  }

  return {
    aggregatedFees,
    numTransactions: seenTxHashes.size,
    txCounts,
    fromBlock: earliestFromBlock,
    toBlock: latestToBlock,
    dailyStats,
    perUserStats,
  };
}

parentPort.on("message", async (allWork) => {
  try {
    const result = await processFiles(allWork);
    parentPort.postMessage(result);
  } catch (error) {
    parentPort.postMessage({ error: error.message });
  }
});
