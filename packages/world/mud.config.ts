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
      "Transfer",
      "Equip",
      "Unequip",
      "Hit",
      "Spawn",
      "Login",
      "Logoff",
      "AttachChip",
      "PowerChip",
      "DetachChip",
      "HitChip",
      "Pickup",
      "InitiateOreReveal",
      "RevealOre",
    ],
    DisplayContentType: ["None", "Text", "Image"],
  },
  tables: {
    // ------------------------------------------------------------
    // Static Data
    // ------------------------------------------------------------
    ObjectTypeMetadata: {
      schema: {
        objectTypeId: "uint16",
        objectCategory: "ObjectCategory",
        stackable: "uint16",
        maxInventorySlots: "uint16",
        mass: "uint32",
        energy: "uint32",
        canPassThrough: "bool",
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
        energy: "uint256",
      },
      key: ["x", "y", "z"],
    },
    // ------------------------------------------------------------
    // Grid
    // ------------------------------------------------------------
    ObjectType: {
      schema: {
        entityId: "bytes32",
        objectTypeId: "uint16",
      },
      key: ["entityId"],
    },
    Position: {
      schema: {
        entityId: "bytes32",
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
        entityId: "bytes32",
      },
      key: ["x", "y", "z"],
    },
    Mass: {
      schema: {
        entityId: "bytes32",
        lastUpdatedTime: "uint256",
        mass: "uint256",
      },
      key: ["entityId"],
    },
    Energy: {
      schema: {
        entityId: "bytes32",
        lastUpdatedTime: "uint256",
        energy: "uint256",
      },
      key: ["entityId"],
    },
    GlobalEnergyPool: {
      schema: {
        energy: "uint256",
      },
      key: [],
    },
    LocalEnergyPool: {
      schema: {
        x: "int32",
        y: "int32",
        z: "int32",
        energy: "uint256",
      },
      key: ["x", "y", "z"],
    },
    // ------------------------------------------------------------
    // Inventory
    // ------------------------------------------------------------
    InventorySlots: {
      schema: {
        ownerEntityId: "bytes32",
        numSlotsUsed: "uint16",
      },
      key: ["ownerEntityId"],
    },
    InventoryObjects: {
      schema: {
        ownerEntityId: "bytes32",
        objectTypeIds: "uint16[]",
      },
      key: ["ownerEntityId"],
    },
    InventoryCount: {
      schema: {
        ownerEntityId: "bytes32",
        objectTypeId: "uint16",
        count: "uint16", // TODO: replace with uint256
      },
      key: ["ownerEntityId", "objectTypeId"],
    },
    InventoryTool: {
      schema: {
        toolEntityId: "bytes32",
        ownerEntityId: "bytes32",
      },
      key: ["toolEntityId"],
    },
    ReverseInventoryTool: {
      schema: {
        ownerEntityId: "bytes32",
        toolEntityIds: "bytes32[]",
      },
      key: ["ownerEntityId"],
    },
    Equipped: {
      schema: {
        ownerEntityId: "bytes32",
        toolEntityId: "bytes32",
      },
      key: ["ownerEntityId"],
    },
    // ------------------------------------------------------------
    // Player
    // ------------------------------------------------------------
    Player: {
      schema: {
        player: "address",
        entityId: "bytes32",
      },
      key: ["player"],
    },
    ReversePlayer: {
      schema: {
        entityId: "bytes32",
        player: "address",
      },
      key: ["entityId"],
    },
    PlayerActivity: {
      schema: {
        entityId: "bytes32",
        lastActionTime: "uint256",
      },
      key: ["entityId"],
    },
    PlayerStatus: {
      schema: {
        entityId: "bytes32",
        isLoggedOff: "bool",
      },
      key: ["entityId"],
    },
    LastKnownPosition: {
      schema: {
        entityId: "bytes32",
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
        entityId: "bytes32",
        chipAddress: "address",
      },
      key: ["entityId"],
    },
    ForceField: {
      schema: {
        x: "int32",
        y: "int32",
        z: "int32",
        forceFieldEntityId: "bytes32",
      },
      key: ["x", "y", "z"],
    },
    DisplayContent: {
      schema: {
        entityId: "bytes32",
        contentType: "DisplayContentType",
        content: "bytes",
      },
      key: ["entityId"],
    },
    // TODO: replace with spawn tiles
    Spawn: {
      schema: {
        x: "int32",
        z: "int32",
        initialized: "bool",
        spawnLowX: "int32",
        spawnHighX: "int32",
        spawnLowZ: "int32",
        spawnHighZ: "int32",
      },
      key: ["x", "z"],
      codegen: {
        storeArgument: true,
      },
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
        committerEntityId: "bytes32",
      },
      key: ["x", "y", "z"],
    },
    Commitment: {
      schema: {
        entityId: "bytes32",
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
        playerEntityId: "bytes32",
        actionType: "ActionType",
        entityId: "bytes32",
        objectTypeId: "uint16",
        coordX: "int32",
        coordY: "int32",
        coordZ: "int32",
        amount: "uint256",
      },
      key: ["playerEntityId"],
      type: "offchainTable",
    },
    // ------------------------------------------------------------
    // Internal
    // ------------------------------------------------------------
    UniqueEntity: {
      schema: {
        value: "uint256",
      },
      key: [],
    },
    BaseEntity: {
      schema: {
        entityId: "bytes32",
        baseEntityId: "bytes32",
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
  systems: {
    GravitySystem: {
      name: "GravitySystem",
      openAccess: false,
      accessList: [],
    },
    ForceFieldSystem: {
      name: "ForceFieldSystem",
      openAccess: false,
      accessList: [],
    },
    MoveHelperSystem: {
      name: "MoveHelperSystem",
      openAccess: false,
      accessList: [],
    },
    TransferHelperSystem: {
      name: "TransferHelperSy",
      openAccess: false,
      accessList: [],
    },
    PipeTransferHelperSystem: {
      name: "PipeTransferHelp",
      openAccess: false,
      accessList: [],
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
