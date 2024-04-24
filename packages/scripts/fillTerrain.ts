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

  const readResult = await publicClient.readContract({
    address: worldAddress as Hex,
    abi: IWorldAbi,
    functionName: "getTerrainObjectTypeId",
    args: [{ x: 1, y: 1, z: 1 }],
    account,
  });
  console.log("readResult", readResult);

  const txResult = await walletClient.writeContract({
    address: worldAddress as Hex,
    abi: IWorldAbi,
    functionName: "getTerrainObjectTypeIdWithCacheSet",
    args: [{ x: 1, y: 1, z: 1 }],
    account,
  });

  console.log("txResult", txResult);

  process.exit(0);
}

main();
