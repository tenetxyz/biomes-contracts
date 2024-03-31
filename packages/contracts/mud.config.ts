import { defineWorld } from "@latticexyz/world";

export default defineWorld({
  tables: {
    ObjectTypeMetadata: {
      schema: {
        objectTypeId: "bytes32",
        isPlayer: "bool",
        isBlock: "bool",
        mass: "uint16",
        stackable: "uint8",
        damage: "uint16",
        durability: "uint24",
        hardness: "uint16",
      },
      key: ["objectTypeId"],
      codegen: {
        storeArgument: true,
      },
    },
    TerrainMetadata: {
      schema: {
        objectTypeId: "bytes32",
        occurenceAddress: "address",
        occurenceSelector: "bytes4",
      },
      key: ["objectTypeId"],
      codegen: {
        storeArgument: true,
      },
    },
    ObjectType: {
      schema: {
        entityId: "bytes32",
        objectTypeId: "bytes32",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    Position: {
      schema: {
        entityId: "bytes32",
        x: "int32",
        y: "int32",
        z: "int32",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    ReversePosition: {
      schema: {
        x: "int32",
        y: "int32",
        z: "int32",
        entityId: "bytes32",
      },
      key: ["x", "y", "z"],
      codegen: {
        storeArgument: true,
      },
    },
    LastKnownPosition: {
      schema: {
        entityId: "bytes32",
        x: "int32",
        y: "int32",
        z: "int32",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    Player: {
      schema: {
        player: "address",
        entityId: "bytes32",
      },
      key: ["player"],
      codegen: {
        storeArgument: true,
      },
    },
    ReversePlayer: {
      schema: {
        entityId: "bytes32",
        player: "address",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    PlayerMetadata: {
      schema: {
        entityId: "bytes32",
        isLoggedOff: "bool",
        lastMoveBlock: "uint256",
        lastHitTime: "uint256",
        numMovesInBlock: "uint32",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    Inventory: {
      schema: {
        entityId: "bytes32",
        ownerEntityId: "bytes32",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    ReverseInventory: {
      schema: {
        ownerEntityId: "bytes32",
        entityIds: "bytes32[]",
      },
      key: ["ownerEntityId"],
      codegen: {
        storeArgument: true,
      },
    },
    ItemMetadata: {
      schema: {
        entityId: "bytes32",
        numUsesLeft: "uint24",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    InventorySlots: {
      schema: {
        ownerEntityId: "bytes32",
        numSlotsUsed: "uint16",
      },
      key: ["ownerEntityId"],
      codegen: {
        storeArgument: true,
      },
    },
    InventoryCount: {
      schema: {
        ownerEntityId: "bytes32",
        objectTypeId: "bytes32",
        count: "uint16",
      },
      key: ["ownerEntityId", "objectTypeId"],
      codegen: {
        storeArgument: true,
      },
    },
    Equipped: {
      schema: {
        entityId: "bytes32",
        inventoryEntityId: "bytes32",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    Health: {
      schema: {
        entityId: "bytes32",
        lastUpdatedTime: "uint256",
        health: "uint16",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    Stamina: {
      schema: {
        entityId: "bytes32",
        lastUpdatedTime: "uint256",
        stamina: "uint32",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    Recipes: {
      schema: {
        recipeId: "bytes32",
        stationObjectTypeId: "bytes32",
        outputObjectTypeId: "bytes32",
        outputObjectTypeAmount: "uint8",
        inputObjectTypeIds: "bytes32[]",
        inputObjectTypeAmounts: "uint8[]",
      },
      key: ["recipeId"],
      codegen: {
        storeArgument: true,
      },
    },
  },
  systems: {
    GravitySystem: {
      name: "GravitySystem",
      openAccess: false,
      accessList: [],
    },
    MineHelperSystem: {
      name: "MineHelperSystem",
      openAccess: false,
      accessList: [],
    },
  },
  modules: [
    {
      name: "UniqueEntityModule",
      root: true,
      args: [],
    },
  ],
});
