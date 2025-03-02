import { defineConfig } from "tsup";

export default defineConfig({
  entry: ["mud.config.ts"],
  target: "esnext",
  format: ["esm", "cjs"],
  dts: true,
  sourcemap: true,
  clean: true,
  minify: true,
  noExternal: ["@latticexyz/world", "@latticexyz/store/internal", "@latticexyz/schema-type/internal"],
});
