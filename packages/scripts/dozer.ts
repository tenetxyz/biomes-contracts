import { Hex, getAddress } from "viem";
import { setupNetwork } from "./setupNetwork";

async function main() {
  const { publicClient, fromBlock, worldAddress, IWorldAbi, account, txOptions, callTx, indexerUrl } =
    await setupNetwork();

  const query = [
    {
      address: worldAddress,
      query: 'SELECT "entityId", "objectTypeId" FROM ObjectType WHERE "objectTypeId" = 84;',
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

  const fetchedData = [];
  for (const row of content.result[0]) {
    // don't include the first row cuz its the header
    if (row[0] == "entityId") continue;
    // if (row[1].toLowerCase() == "0x4bd5A12B75B24418eCB1285aAAd16a05b94f7096".toLowerCase()) {
    //   entityIds.add(row[0]);
    // }
    fetchedData.push(row);
  }
  console.log("fetchedData", fetchedData);

  console.log(`bytes32[] memory entityIds = new bytes32[](${fetchedData.length});`);
  let i = 0;
  for (const data of fetchedData) {
    console.log(`entityIds[${i}] = ${data[0]};`);
    i++;
  }

  // console.log(`GateApprovalsData[] memory approvals = new GateApprovalsData[](${fetchedData.length});`);
  // i = 0;
  // for (const data of fetchedData) {
  //   const players = data[1];
  //   const nfts = data[2];
  //   console.log(`address[] memory players${i} = new address[](${players.length});`);
  //   console.log(`address[] memory nfts${i} = new address[](${nfts.length});`);
  //   let j = 0;
  //   for (const player of players) {
  //     console.log(`players${i}[${j}] = ${getAddress(player)};`);
  //     j++;
  //   }
  //   j = 0;
  //   for (const nft of nfts) {
  //     console.log(`nfts${i}[${j}] = ${getAddress(nft)};`);
  //     j++;
  //   }

  //   console.log(`approvals[${i}] = GateApprovalsData({
  //     players: players${i},
  //     nfts: nfts${i}
  //   });`);
  //   i++;
  // }
}

main();
