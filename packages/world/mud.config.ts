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
      "ExpandForceField",
      "ContractForceField",
    ],
    DisplayContentType: ["None", "Text", "Image"],
    Direction: [
      // Cardinal directions (6)
      "PositiveX",
      "NegativeX",
      "PositiveY",
      "NegativeY",
      "PositiveZ",
      "NegativeZ",
      // Edge directions (12)
      "PositiveXPositiveY",
      "PositiveXNegativeY",
      "NegativeXPositiveY",
      "NegativeXNegativeY",
      "PositiveXPositiveZ",
      "PositiveXNegativeZ",
      "NegativeXPositiveZ",
      "NegativeXNegativeZ",
      "PositiveYPositiveZ",
      "PositiveYNegativeZ",
      "NegativeYPositiveZ",
      "NegativeYNegativeZ",
      // Corner directions (8)
      "PositiveXPositiveYPositiveZ",
      "PositiveXPositiveYNegativeZ",
      "PositiveXNegativeYPositiveZ",
      "PositiveXNegativeYNegativeZ",
      "NegativeXPositiveYPositiveZ",
      "NegativeXPositiveYNegativeZ",
      "NegativeXNegativeYPositiveZ",
      "NegativeXNegativeYNegativeZ",
    ],
  },
  userTypes: {
    ObjectTypeId: { filePath: "./src/ObjectTypeId.sol", type: "uint16" },
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
        stationTypeId: "ObjectTypeId",
        inputTypes: "uint16[]",
        inputAmounts: "uint16[]",
        outputTypes: "uint16[]",
        outputAmounts: "uint16[]",
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
    PlayerPosition: {
      schema: {
        playerEntityId: "EntityId",
        x: "int32",
        y: "int32",
        z: "int32",
      },
      key: ["playerEntityId"],
    },
    ReversePlayerPosition: {
      schema: {
        x: "int32",
        y: "int32",
        z: "int32",
        playerEntityId: "EntityId",
      },
      key: ["x", "y", "z"],
    },
    Orientation: {
      schema: {
        entityId: "EntityId",
        direction: "Direction",
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
    SurfaceChunkByIndex: {
      schema: {
        index: "uint256",
        x: "int32",
        y: "int32",
        z: "int32",
      },
      key: ["index"],
    },
    SurfaceChunkCount: {
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
    ForceFieldFragment: {
      schema: {
        x: "int32",
        y: "int32",
        z: "int32",
        entityId: "EntityId",
        forceFieldId: "EntityId",
        forceFieldCreatedAt: "uint128",
      },
      key: ["x", "y", "z"],
    },
    ForceFieldFragmentPosition: {
      name: "FragmentPosition",
      schema: {
        entityId: "EntityId",
        x: "int32",
        y: "int32",
        z: "int32",
      },
      key: ["entityId"],
    },
    ForceField: {
      schema: {
        entityId: "EntityId",
        createdAt: "uint128",
      },
      key: ["entityId"],
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
    TotalMinedOreCount: {
      schema: {
        count: "uint256",
      },
      key: [],
    },
    MinedOrePosition: {
      schema: {
        index: "uint256",
        x: "int32",
        y: "int32",
        z: "int32",
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
  systems: {
    AdminSystem: {
      deploy: {
        disabled: true,
      },
    },
  },
});
