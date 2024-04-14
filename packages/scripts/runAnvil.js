import { anvil } from "@latticexyz/common/foundry";
import { homedir } from "os";
import path from "path";
import { rmSync } from "fs";

console.log("Cleaning devnode cache");
const userHomeDir = homedir();
rmSync(path.join(userHomeDir, ".foundry", "anvil", "tmp"), {
  recursive: true,
  force: true,
});

const anvilArgs = ["--block-time", "2", "--block-base-fee-per-gas", "0", "--gas-limit", "50000000"];
anvil(anvilArgs);
