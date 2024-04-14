import { defineConfig } from "tsup";

export default defineConfig({
  entry: ["mud.config.ts", "types/ethers-contracts"],
  target: "esnext",
  format: ["esm", "cjs"],
  dts: false,
  sourcemap: true,
  clean: true,
  minify: true,
  external: ["@latticexyz/config", "@latticexyz/world/register"],
});
