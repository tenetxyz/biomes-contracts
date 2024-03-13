import { mudConfig } from "@latticexyz/world/register";
import { resolveTableId } from "@latticexyz/config";

export default mudConfig({
  tables: {
    ObjectTypeMetadata: {
      keySchema: {
        objectTypeId: "bytes32",
      },
      valueSchema: {
        isPlayer: "bool",
        isBlock: "bool",
        mass: "uint16",
        stackable: "uint8",
        damage: "uint16",
        durability: "uint32",
        hardness: "uint16",
        occurenceAddress: "address",
        occurenceSelector: "bytes4",
      },
    },
    ObjectType: {
      keySchema: {
        entityId: "bytes32",
      },
      valueSchema: {
        objectTypeId: "bytes32",
      },
    },
    Position: {
      keySchema: {
        entityId: "bytes32",
      },
      valueSchema: {
        x: "int32",
        y: "int32",
        z: "int32",
      },
    },
    ReversePosition: {
      keySchema: {
        x: "int32",
        y: "int32",
        z: "int32",
      },
      valueSchema: {
        entityId: "bytes32",
      },
    },
    LastKnownPosition: {
      keySchema: {
        entityId: "bytes32",
      },
      valueSchema: {
        x: "int32",
        y: "int32",
        z: "int32",
      },
    },
    Player: {
      keySchema: {
        player: "address",
      },
      valueSchema: {
        entityId: "bytes32",
      },
    },
    ReversePlayer: {
      keySchema: {
        entityId: "bytes32",
      },
      valueSchema: {
        player: "address",
      },
    },
    PlayerMetadata: {
      keySchema: {
        entityId: "bytes32",
      },
      valueSchema: {
        lastMoveBlock: "uint256",
        lastHitBlock: "uint256",
        numMovesInBlock: "uint32",
      },
    },
    Inventory: {
      keySchema: {
        entityId: "bytes32",
      },
      valueSchema: {
        ownerEntityId: "bytes32",
      },
    },
    ItemMetadata: {
      keySchema: {
        entityId: "bytes32",
      },
      valueSchema: {
        numUsesLeft: "uint32",
      },
    },
    InventorySlots: {
      keySchema: {
        ownerEntityId: "bytes32",
      },
      valueSchema: {
        numSlotsUsed: "uint16",
      },
    },
    InventoryCount: {
      keySchema: {
        ownerEntityId: "bytes32",
        objectTypeId: "bytes32",
      },
      valueSchema: {
        count: "uint16",
      },
    },
    Equipped: {
      keySchema: {
        entityId: "bytes32",
      },
      valueSchema: {
        inventoryEntityId: "bytes32",
      },
    },
    Health: {
      keySchema: {
        entityId: "bytes32",
      },
      valueSchema: {
        lastUpdateBlock: "uint256",
        health: "uint16",
      },
    },
    Stamina: {
      keySchema: {
        entityId: "bytes32",
      },
      valueSchema: {
        lastUpdateBlock: "uint256",
        stamina: "uint32",
      },
    },
    Recipes: {
      keySchema: {
        recipeId: "bytes32",
      },
      valueSchema: {
        stationObjectTypeId: "bytes32",
        outputObjectTypeId: "bytes32",
        outputObjectTypeAmount: "uint8",
        inputObjectTypeIds: "bytes32[]",
        inputObjectTypeAmounts: "uint8[]",
      },
    },
  },
  modules: [
    {
      name: "UniqueEntityModule",
      root: true,
      args: [],
    },
    {
      name: "KeysWithValueModule",
      root: true,
      args: [resolveTableId("Inventory")],
    },
  ],
});
