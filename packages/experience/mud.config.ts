import { defineWorld } from "@latticexyz/world";

export default defineWorld({
  // Note: this is required as the world is deployed with this
  deploy: {
    upgradeableWorldImplementation: true,
  },
  enums: {
    ChipType: ["None", "Chest", "ForceField"],
    ShopType: ["None", "Buy", "Sell", "BuySell"],
  },
  namespace: "experience",
  tables: {
    ExperienceMetadata: {
      schema: {
        experience: "address",
        shouldDelegate: "address",
        joinFee: "uint256",
        hookSystemIds: "bytes32[]",
        name: "string",
        description: "string",
      },
      key: ["experience"],
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
    },
    ChipAttachment: {
      schema: {
        entityId: "bytes32",
        attacher: "address",
      },
      key: ["entityId"],
    },
    ItemShop: {
      schema: {
        entityId: "bytes32",
        shopType: "ShopType",
        objectTypeId: "uint8",
        buyPrice: "uint256",
        sellPrice: "uint256",
        paymentToken: "address",
        balance: "uint256",
      },
      key: ["entityId"],
    },
    ChestMetadata: {
      schema: {
        entityId: "bytes32",
        name: "string",
        description: "string",
      },
      key: ["entityId"],
    },
    FFMetadata: {
      schema: {
        entityId: "bytes32",
        name: "string",
        description: "string",
      },
      key: ["entityId"],
    },
    ForceFieldApprovals: {
      schema: {
        entityId: "bytes32",
        players: "address[]",
        nfts: "address[]",
      },
      key: ["entityId"],
    },
    DisplayStatus: {
      schema: {
        experience: "address",
        status: "string",
      },
      key: ["experience"],
      type: "offchainTable",
      codegen: {
        storeArgument: true,
      },
    },
    DisplayRegisterMsg: {
      schema: {
        experience: "address",
        registerMessage: "string",
      },
      key: ["experience"],
      type: "offchainTable",
      codegen: {
        storeArgument: true,
      },
    },
    DisplayUnregisterMsg: {
      schema: {
        experience: "address",
        unregisterMessage: "string",
      },
      key: ["experience"],
      type: "offchainTable",
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
    Players: {
      schema: {
        experience: "address",
        players: "address[]",
      },
      key: ["experience"],
      codegen: {
        storeArgument: true,
      },
    },
    Areas: {
      schema: {
        experience: "address",
        id: "bytes32",
        lowerSouthwestCornerX: "int16",
        lowerSouthwestCornerY: "int16",
        lowerSouthwestCornerZ: "int16",
        sizeX: "int16",
        sizeY: "int16",
        sizeZ: "int16",
        name: "string",
      },
      key: ["experience", "id"],
      codegen: {
        storeArgument: true,
      },
    },
    Builds: {
      schema: {
        experience: "address",
        id: "bytes32",
        name: "string",
        objectTypeIds: "uint8[]",
        relativePositionsX: "int16[]",
        relativePositionsY: "int16[]",
        relativePositionsZ: "int16[]",
      },
      key: ["experience", "id"],
      codegen: {
        storeArgument: true,
      },
    },
    BuildsWithPos: {
      schema: {
        experience: "address",
        id: "bytes32",
        baseWorldCoordX: "int16",
        baseWorldCoordY: "int16",
        baseWorldCoordZ: "int16",
        name: "string",
        objectTypeIds: "uint8[]",
        relativePositionsX: "int16[]",
        relativePositionsY: "int16[]",
        relativePositionsZ: "int16[]",
      },
      key: ["experience", "id"],
      codegen: {
        storeArgument: true,
      },
    },
    Countdown: {
      schema: {
        experience: "address",
        countdownEndTimestamp: "uint256",
        countdownEndBlock: "uint256",
      },
      key: ["experience"],
      codegen: {
        storeArgument: true,
      },
    },
    Tokens: {
      schema: {
        experience: "address",
        tokens: "address[]",
      },
      key: ["experience"],
      codegen: {
        storeArgument: true,
      },
    },
    NFTs: {
      schema: {
        experience: "address",
        nfts: "address[]",
      },
      key: ["experience"],
      codegen: {
        storeArgument: true,
      },
    },
  },
});
