import { defineWorld } from "@latticexyz/world";

export default defineWorld({
  tables: {
    ObjectTypeMetadata: {
      schema: {
        objectTypeId: "uint8",
        isBlock: "bool",
        isTool: "bool",
        miningDifficulty: "uint16",
        stackable: "uint8",
        damage: "uint16",
        durability: "uint24",
      },
      key: ["objectTypeId"],
      codegen: {
        storeArgument: true,
      },
    },
    Terrain: {
      schema: {
        x: "int16",
        y: "int16",
        z: "int16",
        objectTypeId: "uint8",
      },
      key: ["x", "y", "z"],
      codegen: {
        storeArgument: true,
      },
    },
    Recipes: {
      schema: {
        recipeId: "bytes32",
        stationObjectTypeId: "uint8",
        outputObjectTypeId: "uint8",
        outputObjectTypeAmount: "uint8",
        inputObjectTypeIds: "uint8[]",
        inputObjectTypeAmounts: "uint8[]",
      },
      key: ["recipeId"],
      codegen: {
        storeArgument: true,
      },
    },
  },
  modules: [],
});
