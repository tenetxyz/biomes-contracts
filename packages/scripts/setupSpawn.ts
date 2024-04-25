import { setupNetwork } from "./setupNetwork";

async function main() {
  const { txOptions, callTx } = await setupNetwork();

  console.log("Setting up spawn area...");

  await callTx({
    ...txOptions,
    functionName: "initSpawnAreaBottomBorder",
    args: [],
  });

  await callTx({
    ...txOptions,
    functionName: "initSpawnAreaTop",
    args: [],
  });

  await callTx({
    ...txOptions,
    functionName: "initSpawnAreaTopPart2",
    args: [],
  });

  await callTx({
    ...txOptions,
    functionName: "initSpawnAreaBottom",
    args: [],
  });

  await callTx({
    ...txOptions,
    functionName: "initSpawnAreaBottomPart2",
    args: [],
  });

  console.log("Spawn area setup complete.");

  process.exit(0);
}

main();
