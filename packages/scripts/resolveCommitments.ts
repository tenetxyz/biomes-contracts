import { Hex } from "viem";
import { setupNetwork } from "./setupNetwork";

import fs from "fs";
import path from "path";
import { replacer } from "./utils";

async function main() {
  const { publicClient, fromBlock, worldAddress, IWorldAbi, account, txOptions, callTx, indexerUrl } =
    await setupNetwork();

  const query = [
    {
      address: worldAddress,
      query: 'SELECT "entityId", "hasCommitted", "x", "y", "z" FROM Commitment;',
    },
  ];

  console.log("indexerUrl", indexerUrl);
  console.log("query", query);

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
  // console.log(content);
  const resolveData = [];
  for (const row of content.result[0]) {
    // don't include the first row cuz its the header
    if (row[0] == "entityId") continue;
    resolveData.push({
      entityId: row[0],
      coord: {
        x: row[2],
        y: row[3],
        z: row[4],
      },
    });
  }

  const failedEntities = [];

  for (const data of resolveData) {
    console.log(`resolveCoord(${data.entityId}, ${data.coord.x}, ${data.coord.y}, ${data.coord.z});`);
    const [success, receipt] = await callTx({
      ...txOptions,
      functionName: "revealOre",
      args: [data.coord],
    });
    if (!success) {
      console.error(`Failed to reveal ore at ${data.coord.x}, ${data.coord.y}, ${data.coord.z}`);
      failedEntities.push(data.entityId);
      continue;
    }
  }

  const terrainQuery = [
    {
      address: worldAddress,
      query: 'SELECT "x", "y", "z", "blockNumber", "committerEntityId" FROM TerrainCommitmen;',
    },
  ];

  console.log("indexerUrl", indexerUrl);
  console.log("query", terrainQuery);

  // fetch post request
  const terrainResponse = await fetch(indexerUrl, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
    },
    body: JSON.stringify(terrainQuery),
  });
  const terrainContent = await terrainResponse.json();

  const missingBlockhashNumbers = [];
  for (const row of terrainContent.result[0]) {
    if (row[0] == "x") continue;
    if (failedEntities.includes(row[4])) {
      missingBlockhashNumbers.push(row[3]);
    }
  }

  console.log("missingBlockhashNumbers", missingBlockhashNumbers);

  for (const blockNumber of missingBlockhashNumbers) {
    // get block
    const block = await publicClient.getBlock({ blockNumber: blockNumber });
    // console.log("block", block);
    const blockHash = block.hash;
    console.log("blockHash", blockHash, blockNumber);
    const [success, receipt] = await callTx({
      ...txOptions,
      functionName: "setBlockHash",
      args: [blockNumber, blockHash],
    });
    if (!success) {
      throw new Error(`Failed to set block hash for block ${blockNumber}`);
    }
  }

  // re-run the revealOre txs
  for (const data of resolveData) {
    console.log(`resolveCoord(${data.entityId}, ${data.coord.x}, ${data.coord.y}, ${data.coord.z});`);
    const [success, receipt] = await callTx({
      ...txOptions,
      functionName: "revealOre",
      args: [data.coord],
    });
    if (!success) {
      throw new Error(`Failed to reveal ore at ${data.coord.x}, ${data.coord.y}, ${data.coord.z}`);
    }
  }

  console.log("Finished resolving commitments");
}

main();
