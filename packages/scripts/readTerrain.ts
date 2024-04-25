import { createPublicClient, createWalletClient, custom, parseGwei, size } from "viem";
import dotenv from "dotenv";
import { transportObserver } from "@latticexyz/common";
import { Hex } from "viem";
import { mudFoundry } from "@latticexyz/common/chains";
import { fallback } from "viem";
import { webSocket } from "viem";
import { http } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import IWorldAbi from "@biomesaw/terrain/IWorld.abi.json";

import worldsJson from "@biomesaw/terrain/worlds.json";
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

  const currentCachedValue = await publicClient.readContract({
    address: worldAddress as Hex,
    abi: IWorldAbi,
    functionName: "getCachedTerrainObjectTypeId",
    args: [{ x: 359, y: 16, z: -213 }],
    account,
  });
  console.log("Current cached value:", currentCachedValue);

  process.exit(0);
}

async function printReceipt(publicClient: any, txHash: string) {
  const receipt = await publicClient.waitForTransactionReceipt({ hash: txHash });
  console.log("gasUsed", receipt.gasUsed);
}

main();
