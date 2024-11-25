import { Hex, decodeFunctionData, formatEther } from "viem";
import { setupNetwork } from "./setupNetwork";

async function main() {
  const { publicClient, worldAddress, IWorldAbi, account, txOptions, callTx } = await setupNetwork();

  const data =
    "0x894ecc580000000000000000000000001fbcb6061b22a424b687b04ddcbdc2c516de8d3e737900000000000000000000000000004c6f67696e53797374656d000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000064ce80af5a00000000000000000000000000000000000000000000000000000000000000540000000000000000000000000000000000000000000000000000000000000009fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe5300000000000000000000000000000000000000000000000000000000";

  const { functionName, args } = decodeFunctionData({
    abi: IWorldAbi,
    data: data,
  });

  console.log("Function Name:", functionName);
  if (functionName == "batchCallFrom") {
    for (const batchCallArgs of args[0]) {
      const callFromCallData = decodeFunctionData({ abi: IWorldAbi, data: batchCallArgs["callData"] });
      console.log("Call From Function Name:", callFromCallData.functionName);
      console.log("Call From Arguments:", callFromCallData.args);
    }
  } else if (functionName == "callFrom") {
    const callFromCallData = decodeFunctionData({ abi: IWorldAbi, data: args[2] });
    console.log("Call From Function Name:", callFromCallData.functionName);
    console.log("Call From Arguments:", callFromCallData.args);
  }
}

main();
