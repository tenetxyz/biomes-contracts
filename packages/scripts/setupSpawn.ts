import { createPublicClient, createWalletClient, custom, parseGwei } from "viem";
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
  const sharedTxDetails = {
    address: worldAddress as Hex,
    abi: IWorldAbi,
    account,
    maxPriorityFeePerGas: parseGwei("0"),
    gas: 50_000_000n,
  };

  // Note: must be run first!
  try {
    let txDetails = {
      ...sharedTxDetails,
      functionName: "initSpawnAreaBottomBorder",
      args: [],
    };
    let txHash = await walletClient.writeContract(txDetails);
    console.log("txHash", txHash);
    let transaction = await publicClient.waitForTransactionReceipt({ hash: txHash });
    console.log("gasUsed", transaction.gasUsed);
  } catch (e) {
    console.log("initSpawnAreaBottomBorder failed", e);
  }

  try {
    let txDetails = {
      ...sharedTxDetails,
      functionName: "initSpawnAreaTop",
      args: [],
    };
    let txHash = await walletClient.writeContract(txDetails);
    console.log("txHash", txHash);
    let transaction = await publicClient.waitForTransactionReceipt({ hash: txHash });
    console.log("gasUsed", transaction.gasUsed);
  } catch (e) {
    console.log("initSpawnAreaTop failed", e);
  }

  try {
    let txDetails = {
      ...sharedTxDetails,
      functionName: "initSpawnAreaTopPart2",
      args: [],
    };
    let txHash = await walletClient.writeContract(txDetails);
    console.log("txHash", txHash);
    let transaction = await publicClient.waitForTransactionReceipt({ hash: txHash });
    console.log("gasUsed", transaction.gasUsed);
  } catch (e) {
    console.log("initSpawnAreaTopPart2 failed", e);
  }

  try {
    let txDetails = {
      ...sharedTxDetails,
      functionName: "initSpawnAreaBottom",
      args: [],
    };
    let txHash = await walletClient.writeContract(txDetails);
    console.log("txHash", txHash);
    let transaction = await publicClient.waitForTransactionReceipt({ hash: txHash });
    console.log("gasUsed", transaction.gasUsed);
  } catch (e) {
    console.log("initSpawnAreaBottom failed", e);
  }

  try {
    let txDetails = {
      ...sharedTxDetails,
      functionName: "initSpawnAreaBottomPart2",
      args: [],
    };
    let txHash = await walletClient.writeContract(txDetails);
    console.log("txHash", txHash);
    let transaction = await publicClient.waitForTransactionReceipt({ hash: txHash });
    console.log("gasUsed", transaction.gasUsed);
  } catch (e) {
    console.log("initSpawnAreaBottomPart2 failed", e);
  }

  process.exit(0);
}

main();
