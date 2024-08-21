import { defineWorld } from "@latticexyz/world";

export default defineWorld({
  // Note: this is required as the world is deployed with this
  deploy: {
    upgradeableWorldImplementation: true,
  },
  enums: {
    ChipType: ["None", "Chest", "ForceField"],
    ShopType: ["None", "Buy", "Sell", "BuySell"],
    ShopTxType: ["None", "Buy", "Sell"],
    BaseTriggerKind: ["None", "All", "Any", "Seq"],
    LeafTriggerKind: ["None", "MapBeam", "Event", "ChallengeComplete", "Collect"],
    NavigationAidKind: ["None", "Position", "Entity"],
    EventKind: ["None", "ItemShop", "CloseModal", "ChainPlayerAction"],
    BasePredicateKind: ["None", "Object"],
    LeafPredicateKind: ["None", "Value"],
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
      codegen: {
        storeArgument: true,
      },
    },
    ChipAttachment: {
      schema: {
        entityId: "bytes32",
        attacher: "address",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
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
      codegen: {
        storeArgument: true,
      },
    },
    ChestMetadata: {
      schema: {
        entityId: "bytes32",
        name: "string",
        description: "string",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    FFMetadata: {
      schema: {
        entityId: "bytes32",
        name: "string",
        description: "string",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
    },
    ForceFieldApprovals: {
      schema: {
        entityId: "bytes32",
        players: "address[]",
        nfts: "address[]",
      },
      key: ["entityId"],
      codegen: {
        storeArgument: true,
      },
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
    ItemShopNotif: {
      schema: {
        chestEntityId: "bytes32",
        player: "address",
        shopTxType: "ShopTxType",
        objectTypeId: "uint8",
        amount: "uint16",
        price: "uint256",
        paymentToken: "address",
      },
      key: ["chestEntityId"],
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
    TokenMetadata: {
      schema: {
        token: "address",
        creator: "address",
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
    NFTMetadata: {
      schema: {
        nft: "address",
        creator: "address",
        symbol: "string",
        name: "string",
        description: "string",
        icon: "string",
      },
      key: ["nft"],
      codegen: {
        storeArgument: true,
      },
    },
    Quest: {
      schema: {
        id: "bytes32",
        unlockId: "bytes32",
        triggerId: "bytes32",
        nameId: "string",
        displayName: "string",
      },
      key: ["id"],
      codegen: {
        storeArgument: true,
      },
    },
    BaseTrigger: {
      schema: {
        id: "bytes32",
        kind: "BaseTriggerKind",
        triggerIds: "bytes32[]",
      },
      key: ["id"],
      codegen: {
        storeArgument: true,
      },
    },
    LeafTrigger: {
      schema: {
        id: "bytes32",
        kind: "LeafTriggerKind",
        navigationAidKind: "NavigationAidKind",
        navigationAidPosX: "int16",
        navigationAidPosY: "int16",
        navigationAidPosZ: "int16",
        navigaitonAidEntity: "bytes32",
        name: "string",
      },
      key: ["id"],
      codegen: {
        storeArgument: true,
      },
    },
    MapBeamTrigger: {
      schema: {
        id: "bytes32",
        posX: "int16",
        posZ: "int16",
        allowDefaultNavigationAid: "bool",
      },
      key: ["id"],
      codegen: {
        storeArgument: true,
      },
    },
    ChallengeCompleteTrigger: {
      schema: {
        id: "bytes32",
        challengeId: "bytes32",
      },
      key: ["id"],
      codegen: {
        storeArgument: true,
      },
    },
    CollectTrigger: {
      schema: {
        id: "bytes32",
        objectTypeId: "bytes32",
        count: "uint32",
      },
      key: ["id"],
      codegen: {
        storeArgument: true,
      },
    },
    EventTrigger: {
      schema: {
        id: "bytes32",
        eventKind: "EventKind",
        count: "uint32",
        predicateId: "bytes32",
      },
      key: ["id"],
      codegen: {
        storeArgument: true,
      },
    },
    BasePredicate: {
      schema: {
        id: "bytes32",
        kind: "BasePredicateKind",
        fieldKeys: "bytes", // string[]
        fieldPredicateIds: "bytes32[]",
      },
      key: ["id"],
      codegen: {
        storeArgument: true,
      },
    },
    LeafPredicate: {
      schema: {
        id: "bytes32",
        kind: "LeafPredicateKind",
        valueNum: "uint32",
        valueBool: "bool",
        valueId: "bytes32",
        valueString: "string",
      },
      key: ["id"],
      codegen: {
        storeArgument: true,
      },
    },
  },
});
