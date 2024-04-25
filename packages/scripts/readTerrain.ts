import { Hex } from "viem";
import { setupNetwork } from "./setupNetwork";

async function main() {
  const { publicClient, terrainWorldAddress, TerrainIWorldAbi, account } = await setupNetwork();

  const currentCachedValue = await publicClient.readContract({
    address: terrainWorldAddress as Hex,
    abi: TerrainIWorldAbi,
    functionName: "getCachedTerrainObjectTypeId",
    args: [{ x: 359, y: 16, z: -213 }],
    account,
  });
  console.log("Current cached value:", currentCachedValue);
}

main();
