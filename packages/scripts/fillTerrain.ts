import { createPublicClient, createWalletClient, custom } from "viem";
import dotenv from "dotenv";
import { createBurnerAccount, transportObserver } from "@latticexyz/common";
import { Hex } from "viem";
import { mudFoundry } from "@latticexyz/common/chains";
import { fallback } from "viem";
import { webSocket } from "viem";
import { http } from "viem";
import IWorldAbi from "@biomesaw/terrain/IWorld.abi.json";

import worldsJson from "@biomesaw/terrain/worlds.json";

dotenv.config();

const chain = mudFoundry;

async function main() {
  const privateKey = process.env.PRIVATE_KEY;
  if (!privateKey) {
    throw new Error("Missing PRIVATE_KEY in .env file");
  }

  const worldAddress = worldsJson[chain.id]?.address;
  if (!worldAddress) {
    throw new Error("Missing worldAddress in worlds.json file");
  }

  const burnerAccount = createBurnerAccount(privateKey as Hex);

  const publicClient = createPublicClient({
    chain: chain,
    transport: http(),
  });

  const walletClient = createWalletClient({
    chain: mudFoundry,
    transport: transportObserver(fallback([webSocket(), http()])),
    pollingInterval: 1000, // e.g. when waiting for transactions, we poll every 1000ms
    account: burnerAccount,
  });

  const [account] = await walletClient.getAddresses();

  // const readResult = await publicClient.readContract({
  //   address: worldAddress as Hex,
  //   abi: IWorldAbi,
  //   functionName: "getTerrainObjectTypeId",
  //   args: [{ x: 1, y: 1, z: 1 }],
  //   account,
  // });
  // console.log("readResult", readResult);

  const spawnLowX = 363;
  const spawnLowZ = -225;

  const startCorner = { x: spawnLowX, y: 15, z: spawnLowZ };
  const fullSize = { x: 20, y: 10, z: 20 };
  const chunkSize = 6;
  const rangeX = Math.ceil(fullSize.x / chunkSize);
  const rangeY = Math.ceil(fullSize.y / chunkSize);
  const rangeZ = Math.ceil(fullSize.z / chunkSize);

  console.log("Num chunks", rangeX * rangeY * rangeZ);
  for (let x = 0; x < rangeX; x++) {
    for (let y = 0; y < rangeY; y++) {
      for (let z = 0; z < rangeZ; z++) {
        const lowerSouthWestCorner = {
          x: startCorner.x + x * chunkSize,
          y: startCorner.y + y * chunkSize,
          z: startCorner.z + z * chunkSize,
        };
        const size = { x: chunkSize, y: chunkSize, z: chunkSize };
        console.log("fillTerrainCache", lowerSouthWestCorner, size);

        const fillTerrainCacheTx = {
          address: worldAddress as Hex,
          abi: IWorldAbi,
          functionName: "fillTerrainCache",
          args: [lowerSouthWestCorner, size],
          account,
        };
        // const gasEstimate = await publicClient.estimateContractGas(fillTerrainCacheTx);
        // console.log("estimatedGas:", gasEstimate);

        const txHash = await walletClient.writeContract(fillTerrainCacheTx);
        console.log("txHash", txHash);
        // const transaction = await publicClient.waitForTransactionReceipt({ hash: txHash });
        // console.log("gasUsed", transaction.gasUsed);
      }
    }
  }

  process.exit(0);
}

main();
