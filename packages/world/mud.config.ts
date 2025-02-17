import { defineWorld } from "@latticexyz/world";

export default defineWorld({
  deploy: {
    upgradeableWorldImplementation: true,
  },
  enums: {
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
    ObjectTypeId: { filePath: "./src/ObjectTypeIds.sol", type: "uint16" },
    EntityId: { filePath: "./src/EntityId.sol", type: "bytes32" },
    ResourceId: { filePath: "@latticexyz/store/src/ResourceId.sol", type: "bytes32" },
  },
  tables: {
    // ------------------------------------------------------------
    // Static Data
    // ------------------------------------------------------------
    ObjectTypeMetadata: {
      schema: {
        objectTypeId: "ObjectTypeId",
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
        objectTypeId: "ObjectTypeId",
        relativePositionsX: "int32[]",
        relativePositionsY: "int32[]",
        relativePositionsZ: "int32[]",
      },
      key: ["objectTypeId"],
    },
    Recipes: {
      schema: {
        recipeId: "bytes32",
        stationObjectTypeId: "ObjectTypeId",
        outputObjectTypeId: "ObjectTypeId",
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
        objectTypeId: "ObjectTypeId",
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
    ExploredChunk: {
      schema: {
        x: "int32",
        y: "int32",
        z: "int32",
        explorer: "address",
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
        objectTypeId: "ObjectTypeId",
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
        chipSystemId: "ResourceId",
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
    ForceFieldMetadata: {
      schema: {
        x: "int32",
        y: "int32",
        z: "int32",
        totalMassInside: "uint128",
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
    OreCommitment: {
      schema: {
        x: "int32",
        y: "int32",
        z: "int32",
        blockNumber: "uint256",
      },
      key: ["x", "y", "z"],
    },
    MinedOreCount: {
      schema: {
        count: "uint256",
      },
      key: [],
    },
    MinedOre: {
      schema: {
        index: "uint256",
        x: "int32",
        y: "int32",
        z: "int32",
      },
      key: ["index"],
    },
    // TODO: merge with ObjectTypeMetadata?
    // Should we keep track of other objects as well?
    ObjectCount: {
      schema: {
        objectTypeId: "ObjectTypeId",
        count: "uint256",
      },
      key: ["objectTypeId"],
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
  },
});
