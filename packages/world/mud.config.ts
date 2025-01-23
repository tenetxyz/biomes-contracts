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
    UniqueEntity: {
      schema: {
        value: "uint256",
      },
      key: [],
      codegen: {
        storeArgument: true,
      },
    },
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
    ObjectTypeSchema: {
      schema: {
        objectTypeId: "uint8",
        relativePositionsX: "int16[]",
        relativePositionsY: "int16[]",
        relativePositionsZ: "int16[]",
      },
      key: ["objectTypeId"],
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
    Spawn: {
      schema: {
        x: "int16",
        z: "int16",
        initialized: "bool",
        spawnLowX: "int16",
        spawnHighX: "int16",
        spawnLowZ: "int16",
        spawnHighZ: "int16",
      },
      key: ["x", "z"],
      codegen: {
        storeArgument: true,
      },
    },
    BaseEntity: {
      schema: {
        entityId: "bytes32",
        baseEntityId: "bytes32",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    ObjectType: {
      schema: {
        entityId: "bytes32",
        objectTypeId: "uint8",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    Position: {
      schema: {
        entityId: "bytes32",
        x: "int16",
        y: "int16",
        z: "int16",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    ReversePosition: {
      schema: {
        x: "int16",
        y: "int16",
        z: "int16",
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
        x: "int16",
        y: "int16",
        z: "int16",
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
        lastHitTime: "uint256",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    PlayerActivity: {
      schema: {
        entityId: "bytes32",
        lastActionTime: "uint256",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    InventoryTool: {
      schema: {
        toolEntityId: "bytes32",
        ownerEntityId: "bytes32",
      },
      key: ["toolEntityId"],
      codegen: {
        storeArgument: true,
      },
    },
    ReverseInventoryTool: {
      schema: {
        ownerEntityId: "bytes32",
        toolEntityIds: "bytes32[]",
      },
      key: ["ownerEntityId"],
      codegen: {
        storeArgument: true,
      },
    },
    InventoryCount: {
      schema: {
        ownerEntityId: "bytes32",
        objectTypeId: "uint8",
        count: "uint16",
      },
      key: ["ownerEntityId", "objectTypeId"],
      codegen: {
        storeArgument: true,
      },
    },
    InventoryObjects: {
      schema: {
        ownerEntityId: "bytes32",
        objectTypeIds: "uint8[]",
      },
      key: ["ownerEntityId"],
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
    ItemMetadata: {
      schema: {
        toolEntityId: "bytes32",
        numUsesLeft: "uint24",
      },
      key: ["toolEntityId"],
      codegen: {
        storeArgument: true,
      },
    },
    Chip: {
      schema: {
        entityId: "bytes32",
        chipAddress: "address",
        batteryLevel: "uint256",
        lastUpdatedTime: "uint256",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    ShardField: {
      schema: {
        x: "int16",
        y: "int16",
        z: "int16",
        forceFieldEntityId: "bytes32",
      },
      key: ["x", "y", "z"],
      codegen: {
        storeArgument: true,
      },
    },
    Equipped: {
      schema: {
        ownerEntityId: "bytes32",
        toolEntityId: "bytes32",
      },
      key: ["ownerEntityId"],
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
    ExperiencePoints: {
      schema: {
        entityId: "bytes32",
        xp: "uint256",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    DisplayContent: {
      schema: {
        entityId: "bytes32",
        contentType: "DisplayContentType",
        content: "bytes",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    TerrainCommitment: {
      schema: {
        x: "int16",
        y: "int16",
        z: "int16",
        blockNumber: "uint256",
        committerEntityId: "bytes32",
      },
      key: ["x", "y", "z"],
      codegen: {
        storeArgument: true,
      },
    },
    Commitment: {
      schema: {
        entityId: "bytes32",
        hasCommitted: "bool",
        x: "int16",
        y: "int16",
        z: "int16",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    BlockHash: {
      schema: {
        blockNumber: "uint256",
        blockHash: "bytes32",
      },
      key: ["blockNumber"],
      codegen: {
        storeArgument: true,
      },
    },
    BlockPrevrandao: {
      schema: {
        blockNumber: "uint256",
        blockPrevrandao: "uint256",
      },
      key: ["blockNumber"],
      codegen: {
        storeArgument: true,
      },
    },
    PlayerActionNotif: {
      schema: {
        playerEntityId: "bytes32",
        actionType: "ActionType",
        entityId: "bytes32",
        objectTypeId: "uint8",
        coordX: "int16",
        coordY: "int16",
        coordZ: "int16",
        amount: "uint256",
      },
      key: ["playerEntityId"],
      type: "offchainTable",
      codegen: {
        storeArgument: true,
      },
    },
    // -------------------
    // DEPRECATED TABLES
    // -------------------
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
    ChestMetadata: {
      schema: {
        chestEntityId: "bytes32",
        owner: "address",
        onTransferHook: "address",
        strength: "uint256",
        strengthenObjectTypeIds: "uint8[]",
        strengthenObjectTypeAmounts: "uint16[]",
      },
      key: ["chestEntityId"],
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
    ForceFieldSystem: {
      name: "ForceFieldSystem",
      openAccess: false,
      accessList: [],
    },
    MintXPSystem: {
      name: "MintXPSystem",
      openAccess: false,
      accessList: [],
    },
    MineHelperSystem: {
      name: "MineHelperSystem",
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
      artifactPath:
        "@latticexyz/world-modules/out/Unstable_CallWithSignatureModule.sol/Unstable_CallWithSignatureModule.json",
      root: true,
    },
    {
      artifactPath: "@latticexyz/world-modules/out/PuppetModule.sol/PuppetModule.json",
      root: false,
      args: [],
    },
  ],
});
