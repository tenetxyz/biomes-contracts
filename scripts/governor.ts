import { Hex, decodeEventLog, getContract, parseAbi } from "viem";
import { setupNetwork } from "./setupNetwork";
import { resourceToHex } from "@latticexyz/common";
import { storeEventsAbi } from "@latticexyz/store";

import governorAbi from "./abis/governor.json";

async function main() {
  const { publicClient, worldAddress, IWorldAbi, account, txOptions, callTx } = await setupNetwork();

  const governorContractAddress = "0xC66AB83418C20A65C3f8e83B3d11c8C3a6097b6F";

  // Fetch the logs for the ProposalCreated event
  const logs = await publicClient.getLogs({
    address: governorContractAddress,
    events: governorAbi.abi.filter((item) => item.type === "event" && item.name === "ProposalCreated"),
    fromBlock: 0n,
    toBlock: "latest",
  });

  // Decode the logs to get proposal details
  const proposals = logs.map((log) =>
    decodeEventLog({
      abi: governorAbi.abi,
      data: log.data,
      topics: log.topics,
      eventName: "ProposalCreated",
    })
  );

  // Format the proposal details
  console.log(proposals);

  // for (const proposal of proposals) {
  //   console.log("Proposal ID");
  //   console.log(proposal.args.proposalId);
  //   console.log("callData");
  //   console.log(proposal.args.calldatas);
  // }

  // await callTx({
  //   ...txOptions,
  //   address: governorContractAddress,
  //   abi: governorAbi.abi,
  //   functionName: "castVote",
  //   args: [69949111804294035116839134083043907894512685964407266671966419673024431511092n, 1],
  // });

  const proposalState = await publicClient.readContract({
    address: governorContractAddress,
    abi: governorAbi.abi,
    functionName: "state",
    args: [69949111804294035116839134083043907894512685964407266671966419673024431511092n],
    account,
  });
  console.log("Proposal", proposalState);

  process.exit(0);
}

main();
