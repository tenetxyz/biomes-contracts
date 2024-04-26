import { Hex } from "viem";
import { setupNetwork } from "./setupNetwork";

async function main() {
  const { publicClient, worldAddress, IWorldAbi, account } = await setupNetwork();

  const objectTypeAtCoord = await publicClient.readContract({
    address: worldAddress as Hex,
    abi: IWorldAbi,
    functionName: "getObjectTypeIdAtCoord",
    args: [{ x: 373, y: 17, z: -208 }],
    account,
  });
  console.log("Object Type:", objectTypeAtCoord);
}

main();
