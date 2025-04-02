import { defineWorld } from "@latticexyz/world";

export default defineWorld({
  sourceDirectory: "contracts",
  namespace: "dustkit",
  userTypes: {
    ResourceId: {
      filePath: "@latticexyz/store/src/ResourceId.sol",
      type: "bytes32",
    },
  },
  tables: {
    AppRegistry: {
      schema: {
        appId: "ResourceId",
        appConfigUrl: "string",
      },
      key: ["appId"],
    },
  },
});
