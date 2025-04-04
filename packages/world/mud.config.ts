import { defineWorld } from "@latticexyz/world";

export default defineWorld({
  deploy: {
    upgradeableWorldImplementation: true,
  },
  enums: {
    Action: [
      "None",
      "Build",
      "Mine",
      "Move",
      "Craft",
      "Drop",
      "Pickup",
      "Transfer",
      "Spawn",
      "Sleep",
      "Wakeup",
      "FuelMachine",
      "HitMachine",
      "AttachProgram",
      "DetachProgram",
      "AddFragment",
      "RemoveFragment",
      "Death",
    ],
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
    ProgramId: { filePath: "./src/ProgramId.sol", type: "bytes32" },
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
        mass: "uint128",
        energy: "uint128",
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
    RegionMerkleRoot: {
      schema: {
        x: "int32",
        z: "int32",
        root: "bytes32",
      },
      key: ["x", "z"],
    },
    // ------------------------------------------------------------
    // Inventory
    // ------------------------------------------------------------
    Inventory: {
      schema: {
        owner: "EntityId",
        occupiedSlots: "uint16[]", // Slots with at least 1 item
      },
      key: ["owner"],
    },
    InventorySlot: {
      schema: {
        owner: "EntityId",
        slot: "uint16",
        entityId: "EntityId",
        objectType: "ObjectTypeId",
        amount: "uint16",
        // TODO: we could make them bigger but not sure if neeed
        occupiedIndex: "uint16",
        typeIndex: "uint16", // Index in InventoryTypeSlots
      },
      key: ["owner", "slot"],
    },
    InventoryTypeSlots: {
      schema: {
        owner: "EntityId",
        objectType: "ObjectTypeId",
        slots: "uint16[]", // All slots containing this object type
      },
      key: ["owner", "objectType"],
    },
    // ------------------------------------------------------------
    // Movable positions
    // ------------------------------------------------------------
    MovablePosition: {
      schema: {
        entityId: "EntityId",
        x: "int32",
        y: "int32",
        z: "int32",
      },
      key: ["entityId"],
    },
    ReverseMovablePosition: {
      schema: {
        x: "int32",
        y: "int32",
        z: "int32",
        entityId: "EntityId",
      },
      key: ["x", "y", "z"],
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
        lastDepletedTime: "uint128",
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
    // ------------------------------------------------------------
    // Smart Items
    // ------------------------------------------------------------
    EntityProgram: {
      schema: {
        entityId: "EntityId",
        program: "ProgramId",
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
    Machine: {
      schema: {
        entityId: "EntityId",
        createdAt: "uint128",
        depletedTime: "uint128",
      },
      key: ["entityId"],
    },
    DisplayURI: {
      schema: {
        entityId: "EntityId",
        uri: "string",
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
    // Farming
    // ------------------------------------------------------------
    SeedGrowth: {
      schema: {
        entityId: "EntityId",
        fullyGrownAt: "uint128",
      },
      key: ["entityId"],
    },
    // ------------------------------------------------------------
    // Offchain
    // ------------------------------------------------------------
    Notification: {
      schema: {
        playerEntityId: "EntityId",
        timestamp: "uint128",
        action: "Action",
        data: "bytes",
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
