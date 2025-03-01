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
      "Sleep",
      "Wakeup",
      "PowerMachine",
      "HitMachine",
      "AttachChip",
      "DetachChip",
      "InitiateOreReveal",
      "RevealOre",
    ],
    DisplayContentType: ["None", "Text", "Image"],
    FacingDirection: ["PositiveX", "NegativeX", "PositiveY", "NegativeY", "PositiveZ", "NegativeZ"],
  },
  userTypes: {
    ObjectTypeId: { filePath: "./src/ObjectTypeIds.sol", type: "uint16" },
    EntityId: { filePath: "./src/EntityId.sol", type: "bytes32" },
    ResourceId: { filePath: "@latticexyz/store/src/ResourceId.sol", type: "bytes32" },
    Vec3: { filePath: "./src/Vec3.sol", type: "uint96" },
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
    Recipes: {
      schema: {
        recipeId: "bytes32",
        outputTypes: "uint16[]",
        outputAmounts: "uint16[]",
      },
      key: ["recipeId"],
    },
    InitialEnergyPool: {
      schema: {
        position: "Vec3",
        energy: "uint128",
      },
      key: ["position"],
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
        position: "Vec3",
      },
      key: ["entityId"],
    },
    ReversePosition: {
      schema: {
        position: "Vec3",
        entityId: "EntityId",
      },
      key: ["position"],
    },
    PlayerPosition: {
      schema: {
        playerEntityId: "EntityId",
        position: "Vec3",
      },
      key: ["playerEntityId"],
    },
    ReversePlayerPosition: {
      schema: {
        position: "Vec3",
        playerEntityId: "EntityId",
      },
      key: ["position"],
    },
    Orientation: {
      schema: {
        entityId: "EntityId",
        facingDirection: "FacingDirection",
      },
      key: ["entityId"],
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
        drainRate: "uint128",
        accDepletedTime: "uint128",
      },
      key: ["entityId"],
    },
    LocalEnergyPool: {
      schema: {
        position: "Vec3",
        energy: "uint128",
      },
      key: ["position"],
    },
    ExploredChunk: {
      schema: {
        position: "Vec3",
        explorer: "address",
      },
      key: ["position"],
    },
    ExploredChunkByIndex: {
      schema: {
        index: "uint256",
        position: "Vec3",
      },
      key: ["index"],
    },
    ExploredChunkCount: {
      schema: {
        count: "uint256",
      },
      key: [],
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
    BedPlayer: {
      schema: {
        bedEntityId: "EntityId",
        playerEntityId: "EntityId",
        lastAccDepletedTime: "uint128",
      },
      key: ["bedEntityId"],
    },
    PlayerStatus: {
      schema: {
        entityId: "EntityId",
        // TODO: maybe move this to another table?
        bedEntityId: "EntityId",
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
        position: "Vec3",
        forceFieldEntityId: "EntityId",
      },
      key: ["position"],
    },
    ForceFieldMetadata: {
      schema: {
        position: "Vec3",
        totalMassInside: "uint128",
      },
      key: ["position"],
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
        position: "Vec3",
        blockNumber: "uint256",
      },
      key: ["position"],
    },
    TotalMinedOreCount: {
      schema: {
        count: "uint256",
      },
      key: [],
    },
    MinedOrePosition: {
      schema: {
        index: "uint256",
        position: "Vec3",
      },
      key: ["index"],
    },
    MinedOreCount: {
      schema: {
        objectTypeId: "ObjectTypeId",
        count: "uint256",
      },
      key: ["objectTypeId"],
    },
    TotalBurnedOreCount: {
      schema: {
        count: "uint256",
      },
      key: [],
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
