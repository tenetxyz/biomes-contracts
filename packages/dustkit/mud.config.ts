import { defineWorld } from "@latticexyz/world";

export default defineWorld({
  sourceDirectory: "contracts",
  namespace: "dustkit",
  userTypes: {
    ResourceId: {
      type: "bytes32",
      filePath: "@latticexyz/store/src/ResourceId.sol",
    },
    EntityId: { type: "bytes32", filePath: "@dust/world/src/EntityId.sol" },
    ProgramId: { type: "bytes32", filePath: "@dust/world/src/ProgramId.sol" },
  },
  tables: {
    App: {
      schema: {
        app: "ResourceId",
        configUrl: "string",
      },
      key: ["app"],
    },
    ProgramEntity: {
      schema: {
        program: "ProgramId",
        entity: "EntityId", // optional, assumes all entities if empty
        defaultApp: "ResourceId",
      },
      key: ["program", "entity"],
    },
  },
});
