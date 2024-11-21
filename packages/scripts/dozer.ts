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
    if (row[1].toLowerCase() == "0xD45bE5726Da3347eab4F7Cb151E3bc9De3a18749".toLowerCase()) {
      entityIds.add(row[0]);
    }
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