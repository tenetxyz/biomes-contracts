import { defineWorld } from "@latticexyz/world";

export default defineWorld({
  // Note: this is required as the world is deployed with this
  deploy: {
    upgradeableWorldImplementation: true,
  },
  enums: {
    ChipType: ["None", "Chest", "ForceField", "Display"],
    ResourceType: ["None", "Object", "NativeCurrency", "ERC20", "ERC721"],
  },
  userTypes: {
    ResourceId: { filePath: "@latticexyz/store/src/ResourceId.sol", type: "bytes32" },
    EntityId: { filePath: "@biomesaw/world/src/EntityId.sol", type: "bytes32" },
  },
  namespace: "experience",
  tables: {
    NamespaceId: {
      schema: {
        contractAddress: "address",
        namespaceId: "ResourceId",
      },
      key: ["contractAddress"],
      codegen: {
        storeArgument: true,
      },
    },
    ChipMetadata: {
      schema: {
        chipAddress: "address",
        chipType: "ChipType",
        name: "string",
        description: "string",
      },
      key: ["chipAddress"],
      codegen: {
        storeArgument: true,
      },
    },
    ChipAttachment: {
      schema: {
        entityId: "EntityId",
        attacher: "address",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    ChipAdmin: {
      schema: {
        entityId: "EntityId",
        admin: "address",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    SmartItemMetadata: {
      schema: {
        entityId: "EntityId",
        name: "string",
        description: "string",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    ExchangeInfo: {
      schema: {
        entityId: "EntityId",
        exchangeId: "bytes32",
        inResourceType: "ResourceType",
        inResourceId: "bytes32",
        inUnitAmount: "uint256",
        inMaxAmount: "uint256",
        outResourceType: "ResourceType",
        outResourceId: "bytes32",
        outUnitAmount: "uint256",
        outMaxAmount: "uint256",
      },
      key: ["entityId", "exchangeId"],
      codegen: {
        storeArgument: true,
      },
    },
    Exchanges: {
      schema: {
        entityId: "EntityId",
        exchangeIds: "bytes32[]",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    PipeAccess: {
      schema: {
        targetEntityId: "EntityId",
        callerEntityId: "EntityId",
        depositAllowed: "bool",
        withdrawAllowed: "bool",
      },
      key: ["targetEntityId", "callerEntityId"],
      codegen: {
        storeArgument: true,
      },
    },
    PipeAccessList: {
      schema: {
        entityId: "EntityId",
        allowedEntityIds: "bytes32[]",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    GateApprovals: {
      schema: {
        entityId: "EntityId",
        players: "address[]",
        nfts: "address[]",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    Notification: {
      schema: {
        experience: "address",
        player: "address",
        message: "string",
      },
      key: ["experience"],
      type: "offchainTable",
      codegen: {
        storeArgument: true,
      },
    },
    ExchangeNotif: {
      schema: {
        entityId: "EntityId",
        player: "address",
        inResourceType: "ResourceType",
        inResourceId: "bytes32",
        inAmount: "uint256",
        outResourceType: "ResourceType",
        outResourceId: "bytes32",
        outAmount: "uint256",
      },
      key: ["entityId"],
      type: "offchainTable",
      codegen: {
        storeArgument: true,
      },
    },
    Assets: {
      schema: {
        experience: "address",
        asset: "address",
        assetType: "ResourceType",
      },
      key: ["experience", "asset"],
      codegen: {
        storeArgument: true,
      },
    },
    ERC20Metadata: {
      schema: {
        token: "address",
        systemId: "ResourceId",
        creator: "address",
        decimals: "uint8",
        symbol: "string",
        name: "string",
        description: "string",
        icon: "string",
      },
      key: ["token"],
      codegen: {
        storeArgument: true,
      },
    },
    ERC721Metadata: {
      schema: {
        nft: "address",
        systemId: "ResourceId",
        creator: "address",
        symbol: "string",
        name: "string",
        description: "string",
        baseURI: "string",
      },
      key: ["nft"],
      codegen: {
        storeArgument: true,
      },
    },
  },
});
