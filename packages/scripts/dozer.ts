import { Hex } from "viem";
import { setupNetwork } from "./setupNetwork";

import fs from "fs";
import path from "path";
import { replacer } from "./utils";

async function main() {
  const { publicClient, fromBlock, worldAddress, IWorldAbi, account, txOptions, callTx } = await setupNetwork();

  const query = [
    {
      address: "0xf75b1b7bdb6932e487c4aa8d210f4a682abeacf0",
      query: 'SELECT "entityId", "chipAddress" FROM Chip;',
    },
  ];

  const indexerUrl = "https://indexer.mud.redstonechain.com/q";

  const entityIds = new Set();

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
  for (const row of content.result[0]) {
    if (row[1].toLowerCase() == "0xC20fc20006D8FAD1a60978aAab3Fa4fFDD2D92d3".toLowerCase()) {
      entityIds.add(row[0]);
    }
  }

  console.log("entityIds", entityIds);
  let i = 0;
  for (const entityId of entityIds) {
    console.log(`entityIds[${i}] = ${entityId};`);
    i++;
  }
}

main();
