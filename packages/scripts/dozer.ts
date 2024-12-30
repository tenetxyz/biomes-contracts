import { Hex, getAddress } from "viem";
import { setupNetwork } from "./setupNetwork";

async function main() {
  const { publicClient, fromBlock, worldAddress, IWorldAbi, account, txOptions, callTx, indexerUrl } =
    await setupNetwork();

  const query = [
    {
      address: worldAddress,
      query:
        'SELECT "entityId", "shopType", "objectTypeId", "buyPrice", "sellPrice", "paymentToken", "balance" FROM experience__ItemShop;',
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

  console.log(`
    struct ExchangeInfoDataWithEntityId {
      bytes32 entityId;
      ExchangeInfoDataWithExchangeId[] exchangeInfoData;
    }`);

  console.log(
    `ExchangeInfoDataWithEntityId[] memory allExchangeInfos = new ExchangeInfoDataWithEntityId[](${fetchedData.length});`,
  );
  i = 0;

  const nftAddresses: string[] = [
    "0x4e77442a934d997e8121b741af39419e75ef9282",
    "0x4ec4101a17d26657e678a8bc0bb1a485069d759e",
    "0xcc0d2185945df9770288cf1b1a0b53559c017d40",
    "0xda931beb980726f9f77214de9bc9d95bbf2889a9",
    "0xe0ac150d02e4a9808403f94a289bcec20d30a3fb",
    "0xf92c0560b1549328ce43bd17bd70b8218b7217bc",
  ];
  const nftAddressesSet = new Set(nftAddresses.map((address) => address.toLowerCase()));

  for (const data of fetchedData) {
    const objectTypeId = data[2];
    const buyPrice = data[3];
    const sellPrice = data[4];
    const paymentToken = getAddress(data[5]);
    if (nftAddressesSet.has(paymentToken.toLowerCase())) {
      console.log("skipping", paymentToken);
      continue;
    }
    const balance = data[6];
    const isUsingEth = paymentToken == "0x0000000000000000000000000000000000000000";
    const entityId = data[0];
    let buyExchangeInfoData = "";
    let sellExchangeInfoData = "";
    if (data[1] == "1") {
      // Buy
      buyExchangeInfoData = `ExchangeInfoData({
            inResourceType: ResourceType.Object,
            inResourceId: encodeObjectExchangeResourceId(${objectTypeId}),
            inUnitAmount: 1,
            inMaxAmount: ${Number(BigInt(balance) / BigInt(buyPrice))},
            outResourceType: ${isUsingEth ? "ResourceType.NativeCurrency" : "ResourceType.ERC20"},
            outResourceId: encodeAddressExchangeResourceId(${paymentToken}),
            outUnitAmount: ${buyPrice},
            outMaxAmount: ${balance}
        })`;
    } else if (data[1] == "2") {
      // Sell
      sellExchangeInfoData = `ExchangeInfoData({
            inResourceType: ${isUsingEth ? "ResourceType.NativeCurrency" : "ResourceType.ERC20"},
            inResourceId: encodeAddressExchangeResourceId(${paymentToken}),
            inUnitAmount: ${sellPrice},
            inMaxAmount: type(uint256).max,
            outResourceType: ResourceType.Object,
            outResourceId: encodeObjectExchangeResourceId(${objectTypeId}),
            outUnitAmount: 1,
            outMaxAmount: getCount(${entityId}, ${objectTypeId})
        })`;
    } else if (data[1] == "3") {
      // BuySell
      if (buyPrice == 0 && sellPrice == 0) {
        // uniswap
        buyExchangeInfoData = `ExchangeInfoData({
          inResourceType: ResourceType.Object,
          inResourceId: encodeObjectExchangeResourceId(${objectTypeId}),
          inUnitAmount: 1,
          inMaxAmount: numMaxInChest(${objectTypeId}) - getCount(${entityId}, ${objectTypeId}),
          outResourceType: ${isUsingEth ? "ResourceType.NativeCurrency" : "ResourceType.ERC20"},
          outResourceId: encodeAddressExchangeResourceId(${paymentToken}),
          outUnitAmount: 0,
          outMaxAmount: ${balance}
          })`;
        sellExchangeInfoData = `ExchangeInfoData({
            inResourceType: ${isUsingEth ? "ResourceType.NativeCurrency" : "ResourceType.ERC20"},
            inResourceId: encodeAddressExchangeResourceId(${paymentToken}),
            inUnitAmount: 0,
            inMaxAmount: type(uint256).max,
            outResourceType: ResourceType.Object,
            outResourceId: encodeObjectExchangeResourceId(${objectTypeId}),
            outUnitAmount: 1,
            outMaxAmount: getCount(${entityId}, ${objectTypeId}) - 1
        })`;
      } else {
        buyExchangeInfoData = `ExchangeInfoData({
          inResourceType: ResourceType.Object,
          inResourceId: encodeObjectExchangeResourceId(${objectTypeId}),
          inUnitAmount: 1,
          inMaxAmount: ${Number(BigInt(balance) / BigInt(buyPrice))},
          outResourceType: ${isUsingEth ? "ResourceType.NativeCurrency" : "ResourceType.ERC20"},
          outResourceId: encodeAddressExchangeResourceId(${paymentToken}),
          outUnitAmount: ${buyPrice},
          outMaxAmount: ${balance}
          })`;
        sellExchangeInfoData = `ExchangeInfoData({
            inResourceType: ${isUsingEth ? "ResourceType.NativeCurrency" : "ResourceType.ERC20"},
            inResourceId: encodeAddressExchangeResourceId(${paymentToken}),
            inUnitAmount: ${sellPrice},
            inMaxAmount: type(uint256).max,
            outResourceType: ResourceType.Object,
            outResourceId: encodeObjectExchangeResourceId(${objectTypeId}),
            outUnitAmount: 1,
            outMaxAmount: getCount(${entityId}, ${objectTypeId})
        })`;
      }
    }
    const numExchanges = buyExchangeInfoData.length > 0 && sellExchangeInfoData.length > 0 ? 2 : 1;
    console.log(
      `ExchangeInfoDataWithExchangeId[] memory exchangeInfoData${i} = new ExchangeInfoDataWithExchangeId[](${numExchanges});`,
    );
    if (buyExchangeInfoData.length > 0 && sellExchangeInfoData.length > 0) {
      console.log(
        `exchangeInfoData${i}[0] = ExchangeInfoDataWithExchangeId({
          exchangeId: BUY_EXCHANGE_ID,
          exchangeInfoData: ${buyExchangeInfoData}
        });`,
      );
      console.log(
        `exchangeInfoData${i}[1] = ExchangeInfoDataWithExchangeId({
          exchangeId: SELL_EXCHANGE_ID,
          exchangeInfoData: ${sellExchangeInfoData}
        });`,
      );
    } else if (buyExchangeInfoData.length > 0) {
      console.log(
        `exchangeInfoData${i}[0] = ExchangeInfoDataWithExchangeId({
          exchangeId: BUY_EXCHANGE_ID,
          exchangeInfoData: ${buyExchangeInfoData}
        });`,
      );
    } else if (sellExchangeInfoData.length > 0) {
      console.log(
        `exchangeInfoData${i}[0] = ExchangeInfoDataWithExchangeId({
          exchangeId: SELL_EXCHANGE_ID,
          exchangeInfoData: ${sellExchangeInfoData}
        });`,
      );
    } else {
      throw new Error("No exchange info data found");
    }

    console.log(`
        allExchangeInfos[${i}] = ExchangeInfoDataWithEntityId({
            entityId: ${entityId},
            exchangeInfoData: exchangeInfoData${i}
        });
      `);
    i++;
  }
}

main();
