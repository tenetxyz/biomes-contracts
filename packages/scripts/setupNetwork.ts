import { WriteContractParameters, createPublicClient, createWalletClient, custom, parseGwei, size } from "viem";
import dotenv from "dotenv";
import { transportObserver } from "@latticexyz/common";
import { Hex } from "viem";
import { fallback } from "viem";
import { webSocket } from "viem";
import { http } from "viem";
import { Abi, Account, Chain, ContractFunctionName, ContractFunctionArgs } from "viem";

import { privateKeyToAccount } from "viem/accounts";

import IWorldAbi from "@biomesaw/world/IWorld.abi.json";
import worldsJson from "@biomesaw/world/worlds.json";

import { supportedChains } from "./supportedChains";

dotenv.config();

const PROD_CHAIN_ID = supportedChains.find((chain) => chain.name === "Redstone Mainnet")?.id ?? 1337;
const DEV_CHAIN_ID = supportedChains.find((chain) => chain.name === "Foundry")?.id ?? 31337;

const chainId = process.env.NODE_ENV === "production" ? PROD_CHAIN_ID : DEV_CHAIN_ID;

export type SetupNetwork = Awaited<ReturnType<typeof setupNetwork>>;

export async function setupNetwork() {
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

  const txOptions = {
    address: worldAddress as Hex,
    abi: IWorldAbi,
    account,
    chain,
    maxPriorityFeePerGas: parseGwei("0"),
    gas: 50_000_000n,
  };

  async function callTx<
    chain extends Chain | undefined,
    account extends Account | undefined,
    abi extends Abi | readonly unknown[],
    functionName extends ContractFunctionName<abi, "nonpayable" | "payable">,
    args extends ContractFunctionArgs<abi, "nonpayable" | "payable", functionName>,
    chainOverride extends Chain | undefined
  >(
    txData: WriteContractParameters<abi, functionName, args, chain, account, chainOverride>,
    label: string | undefined = undefined
  ) {
    const txHash = await walletClient.writeContract(txData);
    console.log(`${label ?? txData.functionName} txHash: ${txHash}`);
    const receipt = await publicClient.waitForTransactionReceipt({ hash: txHash });
    if (receipt.status !== "success") {
      try {
        await publicClient.simulateContract(txData);
      } catch (e) {
        console.error(e);
        throw new Error(`Failed to simulate ${txData.functionName}`);
      }
    }
    console.log(`${label ?? txData.functionName} gasUsed: ${receipt.gasUsed.toLocaleString()}`);
  }

  return {
    IWorldAbi,
    worldAddress,
    walletClient,
    publicClient,
    txOptions,
    callTx,
    account,
  };
}
