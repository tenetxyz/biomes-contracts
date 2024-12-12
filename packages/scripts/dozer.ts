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
      query: 'SELECT "entityId", "chipAddress" FROM Chip;',
    },
  ];

  const entityIds = new Set();

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
  for (const row of content.result[0]) {
    // don't include the first row cuz its the header
    if (row[0] == "entityId") continue;
    if (row[1].toLowerCase() == "0x4bd5A12B75B24418eCB1285aAAd16a05b94f7096".toLowerCase()) {
      entityIds.add(row[0]);
    }
    // entityIds.add(row[0]);
  }

  console.log("entityIds", entityIds);
  console.log(`bytes32[] memory entityIds = new bytes32[](${entityIds.size});`);
  let i = 0;
  for (const entityId of entityIds) {
    console.log(`entityIds[${i}] = ${entityId};`);
    i++;
  }
}

main();
