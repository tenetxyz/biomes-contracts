import { createPublicClient, createWalletClient, custom, parseGwei, size } from "viem";
import dotenv from "dotenv";
import { transportObserver } from "@latticexyz/common";
import { Hex } from "viem";
import { mudFoundry } from "@latticexyz/common/chains";
import { fallback } from "viem";
import { webSocket } from "viem";
import { http } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import IWorldAbi from "@biomesaw/world/IWorld.abi.json";

import worldsJson from "@biomesaw/world/worlds.json";
import { supportedChains } from "./supportedChains";

dotenv.config();

const PROD_CHAIN_ID = supportedChains.find((chain) => chain.name === "Redstone Mainnet")?.id ?? 1337;
const DEV_CHAIN_ID = supportedChains.find((chain) => chain.name === "Foundry")?.id ?? 31337;

const chainId = process.env.NODE_ENV === "production" ? PROD_CHAIN_ID : DEV_CHAIN_ID;

async function main() {
  const privateKey = process.env.PRIVATE_KEY;
  if (!privateKey) {
    throw new Error("Missing PRIVATE_KEY in .env file");
  }
  const chainIndex = supportedChains.findIndex((c) => c.id === chainId);
  const chain = supportedChains[chainIndex];
  if (!chain) {
    throw new Error(`Chain ${chainId} not found`);
  }
  console.log("Using RPC:", chain.rpcUrls["default"].http);
  console.log("Chain Id:", chain.id);

  const worldAddress = worldsJson[chain.id]?.address;
  if (!worldAddress) {
    throw new Error("Missing worldAddress in worlds.json file");
  }
  console.log("Using WorldAddress:", worldAddress);

  const account = privateKeyToAccount(privateKey as Hex);

  const publicClient = createPublicClient({
    chain: chain,
    transport: http(),
  });

  const walletClient = createWalletClient({
    chain: chain,
    transport: transportObserver(fallback([webSocket(), http()])),
    pollingInterval: 1000, // e.g. when waiting for transactions, we poll every 1000ms
    account: account,
  });

  const [publicKey] = await walletClient.getAddresses();
  console.log("Using Account:", publicKey);

  const spawnLowX = 363;
  const spawnLowZ = -225;
  const spawnHighX = 387;
  const spawnHighZ = -205;

  // Calculate midpoints
  const spawnMidX = (spawnLowX + spawnHighX) / 2;
  const spawnMidZ = (spawnLowZ + spawnHighZ) / 2;

  const minY = 10;
  const maxY = 15;

  // 10 hours
  // const fullSize = { x: 300, y: maxY, z: 300 };

  // 6 hours
  const fullSize = { x: 150, y: maxY, z: 150 };

  // 40 minutes
  // const fullSize = { x: 50, y: maxY, z: 50 };
  // const fullSize = { x: 20, y: maxY, z: 20 };

  const startCorner = { x: Math.floor(spawnMidX - fullSize.x / 2), y: minY, z: Math.floor(spawnMidZ - fullSize.z / 2) };

  const chunkSize = 5;
  const rangeX = Math.ceil(fullSize.x / chunkSize);
  const rangeY = Math.ceil(fullSize.y / chunkSize);
  const rangeZ = Math.ceil(fullSize.z / chunkSize);
  console.log(
    "Covered Area:",
    JSON.stringify({
      lowerSouthwestCorner: startCorner,
      size: fullSize,
    })
  );

  const numTxs = rangeX * rangeY * rangeZ;
  console.log("Num Txs:", numTxs);
  const timePerTx = 5;
  const totalSeconds = numTxs * timePerTx;
  console.log("Total Time:", totalSeconds / 60, "minutes", totalSeconds / (60 * 60), "hours");

  let nonce = await publicClient.getTransactionCount({
    address: publicKey as Hex,
  });
  console.log("Latest nonce:", nonce);

  // return;

  let txCount = 0;
  for (let x = 0; x < rangeX; x++) {
    for (let y = 0; y < rangeY; y++) {
      for (let z = 0; z < rangeZ; z++) {
        txCount += 1;
        console.log("Tx", txCount, "of", numTxs, "(", Math.round((txCount / numTxs) * 100), "% )");
        const lowerSouthWestCorner = {
          x: startCorner.x + x * chunkSize,
          y: startCorner.y + y * chunkSize,
          z: startCorner.z + z * chunkSize,
        };

        try {
          const currentCachedValue = await publicClient.readContract({
            address: worldAddress as Hex,
            abi: IWorldAbi,
            functionName: "getObjectTypeIdAtCoord",
            args: [lowerSouthWestCorner],
            account,
          });
          if (currentCachedValue != 0) {
            console.log("Skipping", lowerSouthWestCorner, "already filled");
            continue;
          }

          const size = { x: chunkSize, y: chunkSize, z: chunkSize };
          console.log("fillObjectTypeWithComputedTerrainCache", lowerSouthWestCorner, size);
          nonce += 1;

          const fillTerrainCacheTx = {
            address: worldAddress as Hex,
            abi: IWorldAbi,
            functionName: "fillObjectTypeWithComputedTerrainCache",
            args: [lowerSouthWestCorner, size],
            account,
            maxPriorityFeePerGas: parseGwei("0"),
            gas: 50_000_000n,
            // nonce: nonce,
          };
          // const gasEstimate = await publicClient.estimateContractGas(fillTerrainCacheTx);
          // console.log("estimatedGas:", gasEstimate);

          const txHash = await walletClient.writeContract(fillTerrainCacheTx);
          console.log("txHash", txHash);
          await printReceipt(publicClient, txHash);
          // wait 1 second
          // await new Promise((resolve) => setTimeout(resolve, 1000));
        } catch (e) {
          console.log("Failed to fill", lowerSouthWestCorner, "with error", e);
        }
      }
    }
  }

  process.exit(0);
}

async function printReceipt(publicClient: any, txHash: string) {
  const receipt = await publicClient.waitForTransactionReceipt({ hash: txHash });
  console.log("gasUsed", receipt.gasUsed);
}

main();
