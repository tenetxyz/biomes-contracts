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
import IExperienceAbi from "@biomesaw/experience/IWorld.abi.json";
import CallWithSignatureAbi from "@latticexyz/world-modules/out/Unstable_CallWithSignatureSystem.sol/Unstable_CallWithSignatureSystem.abi.json";
import ERC20SystemAbi from "@latticexyz/world-modules/out/ERC20System.sol/ERC20System.abi.json";
import ERC721SystemAbi from "@latticexyz/world-modules/out/ERC721System.sol/ERC721System.abi.json";
import worldsJson from "@biomesaw/world/worlds.json";

import { supportedChains } from "./supportedChains";

dotenv.config();

const PROD_CHAIN_ID = supportedChains.find((chain) => chain.name === "Redstone")?.id ?? 1337;
const TESNET_CHAIN_ID = supportedChains.find((chain) => chain.name === "Garnet Holesky")?.id ?? 1337;
const DEV_CHAIN_ID = supportedChains.find((chain) => chain.name === "Foundry")?.id ?? 31337;

const chainId =
  process.env.NODE_ENV === "mainnet"
    ? PROD_CHAIN_ID
    : process.env.NODE_ENV === "testnet"
      ? TESNET_CHAIN_ID
      : DEV_CHAIN_ID;

const indexerUrl =
  process.env.NODE_ENV === "mainnet"
    ? "https://indexer.mud.redstonechain.com/q"
    : process.env.NODE_ENV === "testnet"
      ? "https://indexer.mud.garnetchain.com/q"
      : "";

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
  const fromBlock = worldsJson[chain.id]?.blockNumber ?? 0;

  const account = privateKeyToAccount(privateKey as Hex);

  const publicClient = createPublicClient({
    chain: chain,
    transport: http(undefined, {
      batch: {
        batchSize: 100,
        wait: 1000,
      },
    }),
  });

  const walletClient = createWalletClient({
    chain: chain,
    transport: transportObserver(
      fallback([
        webSocket(),
        http(undefined, {
          batch: {
            batchSize: 100,
            wait: 1000,
          },
        }),
      ]),
    ),
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
    maxPriorityFeePerGas: 1n,
    // gas: 50_000_000n,
  };

  async function callTx<
    chain extends Chain | undefined,
    account extends Account | undefined,
    abi extends Abi | readonly unknown[],
    functionName extends ContractFunctionName<abi, "nonpayable" | "payable">,
    args extends ContractFunctionArgs<abi, "nonpayable" | "payable", functionName>,
    chainOverride extends Chain | undefined,
  >(
    txData: WriteContractParameters<abi, functionName, args, chain, account, chainOverride>,
    label: string | undefined = undefined,
  ) {
    let txHash: Hex;
    try {
      txHash = await walletClient.writeContract(txData);
    } catch (e) {
      console.error(e);
      return [false, e];
    }
    console.log(`${label ?? txData.functionName} txHash: ${txHash}`);
    const receipt = await publicClient.waitForTransactionReceipt({
      hash: txHash,
      pollingInterval: 1_000,
      retryDelay: 2_000,
      timeout: 60_000,
      confirmations: 0,
    });
    if (receipt.status !== "success") {
      try {
        console.log(`Simulating transaction: ${txData.functionName}`);
        await publicClient.simulateContract(txData);
      } catch (e) {
        console.error(e);
        return [false, e];
      }
    }
    console.log(`${label ?? txData.functionName} gasUsed: ${receipt.gasUsed.toLocaleString()}`);
    return [true, receipt];
  }

  const allAbis = [IWorldAbi, IExperienceAbi, CallWithSignatureAbi, ERC20SystemAbi, ERC721SystemAbi];

  return {
    IWorldAbi,
    allAbis,
    worldAddress,
    walletClient,
    publicClient,
    txOptions,
    indexerUrl,
    callTx,
    account,
    fromBlock,
  };
}
