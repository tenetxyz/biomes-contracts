import { defineWorld } from "@latticexyz/world";

export default defineWorld({
  tables: {
    Terrain: {
      schema: {
        worldAddress: "address",
        x: "int32",
        y: "int32",
        z: "int32",
        objectTypeId: "bytes32",
      },
      key: ["worldAddress", "x", "y", "z"],
      codegen: {
        storeArgument: true,
      },
    },
  },
  modules: [],
});
