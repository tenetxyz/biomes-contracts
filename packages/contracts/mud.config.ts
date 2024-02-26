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
        durability: "uint16",
        damage: "uint16",
        occurence: "bytes4",
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
      // TODO: Remove this table once KeyWithValueModule is more gas efficient for single key lookups
      keySchema: {
        x: "int32",
        y: "int32",
        z: "int32",
      },
      valueSchema: {
        entityId: "bytes32",
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
    PlayerMetadata: {
      keySchema: {
        entityId: "bytes32",
      },
      valueSchema: {
        lastMoveBlock: "uint256",
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
        numUsesLeft: "uint16",
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
        inputObjectTypeIds: "bytes32[]",
        inputObjectTypeAmounts: "uint8[]",
        outputObjectTypeIds: "bytes32[]",
        outputObjectTypeAmounts: "uint8[]",
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
