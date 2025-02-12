import { defineWorld } from "@latticexyz/world";

export default defineWorld({
  deploy: {
    upgradeableWorldImplementation: true,
  },
  enums: {
    ObjectCategory: ["None", "Block", "Item", "Tool", "Player"],
    ActionType: [
      "None",
      "Build",
      "Mine",
      "Move",
      "Craft",
      "Drop",
      "Pickup",
      "Transfer",
      "Equip",
      "Unequip",
      "Spawn",
      "Login",
      "Logoff",
      "PowerMachine",
      "HitMachine",
      "AttachChip",
      "DetachChip",
      "InitiateOreReveal",
      "RevealOre",
    ],
    DisplayContentType: ["None", "Text", "Image"],
  },
  userTypes: {
    EntityId: { filePath: "./src/EntityId.sol", type: "bytes32" },
  },
  tables: {
    // ------------------------------------------------------------
    // Static Data
    // ------------------------------------------------------------
    ObjectTypeMetadata: {
      schema: {
        objectTypeId: "uint16",
        objectCategory: "ObjectCategory",
        canPassThrough: "bool",
        stackable: "uint16",
        maxInventorySlots: "uint16",
        mass: "uint32",
        energy: "uint32",
      },
      key: ["objectTypeId"],
    },
    ObjectTypeSchema: {
      schema: {
        objectTypeId: "uint16",
        relativePositionsX: "int32[]",
        relativePositionsY: "int32[]",
        relativePositionsZ: "int32[]",
      },
      key: ["objectTypeId"],
    },
    Recipes: {
      schema: {
        recipeId: "bytes32",
        stationObjectTypeId: "uint16",
        outputObjectTypeId: "uint16",
        outputObjectTypeAmount: "uint16",
        inputObjectTypeIds: "uint16[]",
        inputObjectTypeAmounts: "uint16[]",
      },
      key: ["recipeId"],
    },
    InitialEnergyPool: {
      schema: {
        x: "int32",
        y: "int32",
        z: "int32",
        energy: "uint128",
      },
      key: ["x", "y", "z"],
    },
    // ------------------------------------------------------------
    // Grid
    // ------------------------------------------------------------
    ObjectType: {
      schema: {
        entityId: "EntityId",
        objectTypeId: "uint16",
      },
      key: ["entityId"],
    },
    Position: {
      schema: {
        entityId: "EntityId",
        x: "int32",
        y: "int32",
        z: "int32",
      },
      key: ["entityId"],
    },
    ReversePosition: {
      schema: {
        x: "int32",
        y: "int32",
        z: "int32",
        entityId: "EntityId",
      },
      key: ["x", "y", "z"],
    },
    Mass: {
      schema: {
        entityId: "EntityId",
        mass: "uint128",
      },
      key: ["entityId"],
    },
    Energy: {
      schema: {
        entityId: "EntityId",
        lastUpdatedTime: "uint128",
        energy: "uint128",
      },
      key: ["entityId"],
    },
    LocalEnergyPool: {
      schema: {
        x: "int32",
        y: "int32",
        z: "int32",
        energy: "uint128",
      },
      key: ["x", "y", "z"],
    },
    // ------------------------------------------------------------
    // Inventory
    // ------------------------------------------------------------
    InventorySlots: {
      schema: {
        ownerEntityId: "EntityId",
        numSlotsUsed: "uint16",
      },
      key: ["ownerEntityId"],
    },
    InventoryObjects: {
      schema: {
        ownerEntityId: "EntityId",
        objectTypeIds: "uint16[]",
      },
      key: ["ownerEntityId"],
    },
    InventoryCount: {
      schema: {
        ownerEntityId: "EntityId",
        objectTypeId: "uint16",
        count: "uint16",
      },
      key: ["ownerEntityId", "objectTypeId"],
    },
    InventoryEntity: {
      schema: {
        entityId: "EntityId",
        ownerEntityId: "EntityId",
      },
      key: ["entityId"],
    },
    ReverseInventoryEntity: {
      schema: {
        ownerEntityId: "EntityId",
        entityIds: "bytes32[]",
      },
      key: ["ownerEntityId"],
    },
    Equipped: {
      schema: {
        ownerEntityId: "EntityId",
        entityId: "EntityId",
      },
      key: ["ownerEntityId"],
    },
    // ------------------------------------------------------------
    // Player
    // ------------------------------------------------------------
    Player: {
      schema: {
        player: "address",
        entityId: "EntityId",
      },
      key: ["player"],
    },
    ReversePlayer: {
      schema: {
        entityId: "EntityId",
        player: "address",
      },
      key: ["entityId"],
    },
    PlayerActivity: {
      schema: {
        entityId: "EntityId",
        lastActionTime: "uint128",
      },
      key: ["entityId"],
    },
    PlayerStatus: {
      schema: {
        entityId: "EntityId",
        isLoggedOff: "bool",
      },
      key: ["entityId"],
    },
    LastKnownPosition: {
      schema: {
        entityId: "EntityId",
        x: "int32",
        y: "int32",
        z: "int32",
      },
      key: ["entityId"],
    },
    // ------------------------------------------------------------
    // Smart Items
    // ------------------------------------------------------------
    Chip: {
      schema: {
        entityId: "EntityId",
        chipAddress: "address",
      },
      key: ["entityId"],
    },
    ForceField: {
      schema: {
        x: "int32",
        y: "int32",
        z: "int32",
        forceFieldEntityId: "EntityId",
      },
      key: ["x", "y", "z"],
    },
    DisplayContent: {
      schema: {
        entityId: "EntityId",
        contentType: "DisplayContentType",
        content: "bytes",
      },
      key: ["entityId"],
    },
    // ------------------------------------------------------------
    // Ores
    // ------------------------------------------------------------
    TerrainCommitment: {
      schema: {
        x: "int32",
        y: "int32",
        z: "int32",
        blockNumber: "uint256",
        committerEntityId: "EntityId",
      },
      key: ["x", "y", "z"],
    },
    Commitment: {
      schema: {
        entityId: "EntityId",
        hasCommitted: "bool",
        x: "int32",
        y: "int32",
        z: "int32",
      },
      key: ["entityId"],
    },
    // ------------------------------------------------------------
    // Offchain
    // ------------------------------------------------------------
    PlayerActionNotif: {
      schema: {
        playerEntityId: "EntityId",
        actionType: "ActionType",
        actionData: "bytes",
      },
      key: ["playerEntityId"],
      type: "offchainTable",
    },
    // ------------------------------------------------------------
    // Internal
    // ------------------------------------------------------------
    WorldStatus: {
      schema: {
        inMaintenance: "bool",
      },
      key: [],
    },
    UniqueEntity: {
      schema: {
        value: "uint256",
      },
      key: [],
    },
    BaseEntity: {
      schema: {
        entityId: "EntityId",
        baseEntityId: "EntityId",
      },
      key: ["entityId"],
    },
    BlockHash: {
      schema: {
        blockNumber: "uint256",
        blockHash: "bytes32",
      },
      key: ["blockNumber"],
    },
    BlockPrevrandao: {
      schema: {
        blockNumber: "uint256",
        blockPrevrandao: "uint256",
      },
      key: ["blockNumber"],
    },
  },
  modules: [
    {
      artifactPath: "@latticexyz/world-modules/out/PuppetModule.sol/PuppetModule.json",
      root: false,
      args: [],
    },
  ],
});
