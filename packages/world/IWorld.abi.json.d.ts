declare const abi: [
  {
    "type": "function",
    "name": "activate",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "EntityId"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "activatePlayer",
    "inputs": [
      {
        "name": "player",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "adminAddToInventory",
    "inputs": [
      {
        "name": "ownerEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "objectTypeId",
        "type": "uint16",
        "internalType": "ObjectTypeId"
      },
      {
        "name": "numObjectsToAdd",
        "type": "uint16",
        "internalType": "uint16"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "adminAddToolToInventory",
    "inputs": [
      {
        "name": "ownerEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "toolObjectTypeId",
        "type": "uint16",
        "internalType": "ObjectTypeId"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "EntityId"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "adminRemoveFromInventory",
    "inputs": [
      {
        "name": "ownerEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "objectTypeId",
        "type": "uint16",
        "internalType": "ObjectTypeId"
      },
      {
        "name": "numObjectsToRemove",
        "type": "uint16",
        "internalType": "uint16"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "adminRemoveToolFromInventory",
    "inputs": [
      {
        "name": "ownerEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "toolEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "attachChip",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "chipSystemId",
        "type": "bytes32",
        "internalType": "ResourceId"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "attachChipWithExtraData",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "chipSystemId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "extraData",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "batchCall",
    "inputs": [
      {
        "name": "systemCalls",
        "type": "tuple[]",
        "internalType": "struct SystemCallData[]",
        "components": [
          {
            "name": "systemId",
            "type": "bytes32",
            "internalType": "ResourceId"
          },
          {
            "name": "callData",
            "type": "bytes",
            "internalType": "bytes"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "returnDatas",
        "type": "bytes[]",
        "internalType": "bytes[]"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "batchCallFrom",
    "inputs": [
      {
        "name": "systemCalls",
        "type": "tuple[]",
        "internalType": "struct SystemCallFromData[]",
        "components": [
          {
            "name": "from",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "systemId",
            "type": "bytes32",
            "internalType": "ResourceId"
          },
          {
            "name": "callData",
            "type": "bytes",
            "internalType": "bytes"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "returnDatas",
        "type": "bytes[]",
        "internalType": "bytes[]"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "build",
    "inputs": [
      {
        "name": "buildObjectTypeId",
        "type": "uint16",
        "internalType": "ObjectTypeId"
      },
      {
        "name": "baseCoord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "EntityId"
      }
    ],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "buildWithDirection",
    "inputs": [
      {
        "name": "buildObjectTypeId",
        "type": "uint16",
        "internalType": "ObjectTypeId"
      },
      {
        "name": "baseCoord",
        "type": "uint96",
        "internalType": "Vec3"
      },
      {
        "name": "direction",
        "type": "uint8",
        "internalType": "enum Direction"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "EntityId"
      }
    ],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "buildWithExtraData",
    "inputs": [
      {
        "name": "buildObjectTypeId",
        "type": "uint16",
        "internalType": "ObjectTypeId"
      },
      {
        "name": "baseCoord",
        "type": "uint96",
        "internalType": "Vec3"
      },
      {
        "name": "direction",
        "type": "uint8",
        "internalType": "enum Direction"
      },
      {
        "name": "extraData",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "EntityId"
      }
    ],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "call",
    "inputs": [
      {
        "name": "systemId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "callData",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "callFrom",
    "inputs": [
      {
        "name": "delegator",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "systemId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "callData",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "computeBoundaryFragments",
    "inputs": [
      {
        "name": "forceFieldEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "fromFragmentCoord",
        "type": "uint96",
        "internalType": "Vec3"
      },
      {
        "name": "toFragmentCoord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint96[]",
        "internalType": "Vec3[]"
      },
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "contractForceField",
    "inputs": [
      {
        "name": "forceFieldEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "fromFragmentCoord",
        "type": "uint96",
        "internalType": "Vec3"
      },
      {
        "name": "toFragmentCoord",
        "type": "uint96",
        "internalType": "Vec3"
      },
      {
        "name": "parents",
        "type": "uint256[]",
        "internalType": "uint256[]"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "contractForceFieldWithExtraData",
    "inputs": [
      {
        "name": "forceFieldEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "fromFragmentCoord",
        "type": "uint96",
        "internalType": "Vec3"
      },
      {
        "name": "toFragmentCoord",
        "type": "uint96",
        "internalType": "Vec3"
      },
      {
        "name": "parents",
        "type": "uint256[]",
        "internalType": "uint256[]"
      },
      {
        "name": "extraData",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "craft",
    "inputs": [
      {
        "name": "recipeId",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "craftWithStation",
    "inputs": [
      {
        "name": "recipeId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "stationEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "creator",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "deleteRecord",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "detachChip",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "EntityId"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "detachChipWithExtraData",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "extraData",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "drop",
    "inputs": [
      {
        "name": "dropObjectTypeId",
        "type": "uint16",
        "internalType": "ObjectTypeId"
      },
      {
        "name": "numToDrop",
        "type": "uint16",
        "internalType": "uint16"
      },
      {
        "name": "coord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "dropTool",
    "inputs": [
      {
        "name": "toolEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "coord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "dropTools",
    "inputs": [
      {
        "name": "toolEntityIds",
        "type": "bytes32[]",
        "internalType": "EntityId[]"
      },
      {
        "name": "coord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "eat",
    "inputs": [
      {
        "name": "objectTypeId",
        "type": "uint16",
        "internalType": "ObjectTypeId"
      },
      {
        "name": "numToEat",
        "type": "uint16",
        "internalType": "uint16"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "equip",
    "inputs": [
      {
        "name": "inventoryEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "expandForceField",
    "inputs": [
      {
        "name": "forceFieldEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "refFragmentCoord",
        "type": "uint96",
        "internalType": "Vec3"
      },
      {
        "name": "fromFragmentCoord",
        "type": "uint96",
        "internalType": "Vec3"
      },
      {
        "name": "toFragmentCoord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "expandForceFieldWithExtraData",
    "inputs": [
      {
        "name": "forceFieldEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "refFragmentCoord",
        "type": "uint96",
        "internalType": "Vec3"
      },
      {
        "name": "fromFragmentCoord",
        "type": "uint96",
        "internalType": "Vec3"
      },
      {
        "name": "toFragmentCoord",
        "type": "uint96",
        "internalType": "Vec3"
      },
      {
        "name": "extraData",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "exploreChunk",
    "inputs": [
      {
        "name": "chunkCoord",
        "type": "uint96",
        "internalType": "Vec3"
      },
      {
        "name": "chunkData",
        "type": "bytes",
        "internalType": "bytes"
      },
      {
        "name": "merkleProof",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "exploreRegionEnergy",
    "inputs": [
      {
        "name": "regionCoord",
        "type": "uint96",
        "internalType": "Vec3"
      },
      {
        "name": "vegetationCount",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "merkleProof",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "fillBucket",
    "inputs": [
      {
        "name": "waterCoord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "getAllRandomSpawnCoords",
    "inputs": [
      {
        "name": "sender",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [
      {
        "name": "spawnCoords",
        "type": "uint96[]",
        "internalType": "Vec3[]"
      },
      {
        "name": "blockNumbers",
        "type": "uint256[]",
        "internalType": "uint256[]"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getDisplayContent",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "EntityId"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple",
        "internalType": "struct DisplayContentData",
        "components": [
          {
            "name": "contentType",
            "type": "uint8",
            "internalType": "enum DisplayContentType"
          },
          {
            "name": "content",
            "type": "bytes",
            "internalType": "bytes"
          }
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getDynamicField",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      },
      {
        "name": "dynamicFieldIndex",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getDynamicFieldLength",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      },
      {
        "name": "dynamicFieldIndex",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getDynamicFieldSlice",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      },
      {
        "name": "dynamicFieldIndex",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "start",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "end",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "data",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getEntityData",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "EntityId"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple",
        "internalType": "struct EntityData",
        "components": [
          {
            "name": "entityId",
            "type": "bytes32",
            "internalType": "EntityId"
          },
          {
            "name": "baseEntityId",
            "type": "bytes32",
            "internalType": "EntityId"
          },
          {
            "name": "objectTypeId",
            "type": "uint16",
            "internalType": "ObjectTypeId"
          },
          {
            "name": "position",
            "type": "uint96",
            "internalType": "Vec3"
          },
          {
            "name": "orientation",
            "type": "uint8",
            "internalType": "enum Direction"
          },
          {
            "name": "inventory",
            "type": "tuple[]",
            "internalType": "struct InventoryObject[]",
            "components": [
              {
                "name": "objectTypeId",
                "type": "uint16",
                "internalType": "ObjectTypeId"
              },
              {
                "name": "numObjects",
                "type": "uint16",
                "internalType": "uint16"
              },
              {
                "name": "inventoryEntities",
                "type": "tuple[]",
                "internalType": "struct InventoryEntity[]",
                "components": [
                  {
                    "name": "entityId",
                    "type": "bytes32",
                    "internalType": "EntityId"
                  },
                  {
                    "name": "mass",
                    "type": "uint128",
                    "internalType": "uint128"
                  }
                ]
              }
            ]
          },
          {
            "name": "chipSystemId",
            "type": "bytes32",
            "internalType": "ResourceId"
          },
          {
            "name": "mass",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "energy",
            "type": "tuple",
            "internalType": "struct EnergyData",
            "components": [
              {
                "name": "lastUpdatedTime",
                "type": "uint128",
                "internalType": "uint128"
              },
              {
                "name": "energy",
                "type": "uint128",
                "internalType": "uint128"
              },
              {
                "name": "drainRate",
                "type": "uint128",
                "internalType": "uint128"
              },
              {
                "name": "accDepletedTime",
                "type": "uint128",
                "internalType": "uint128"
              }
            ]
          }
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getEntityDataAtCoord",
    "inputs": [
      {
        "name": "coord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple",
        "internalType": "struct EntityData",
        "components": [
          {
            "name": "entityId",
            "type": "bytes32",
            "internalType": "EntityId"
          },
          {
            "name": "baseEntityId",
            "type": "bytes32",
            "internalType": "EntityId"
          },
          {
            "name": "objectTypeId",
            "type": "uint16",
            "internalType": "ObjectTypeId"
          },
          {
            "name": "position",
            "type": "uint96",
            "internalType": "Vec3"
          },
          {
            "name": "orientation",
            "type": "uint8",
            "internalType": "enum Direction"
          },
          {
            "name": "inventory",
            "type": "tuple[]",
            "internalType": "struct InventoryObject[]",
            "components": [
              {
                "name": "objectTypeId",
                "type": "uint16",
                "internalType": "ObjectTypeId"
              },
              {
                "name": "numObjects",
                "type": "uint16",
                "internalType": "uint16"
              },
              {
                "name": "inventoryEntities",
                "type": "tuple[]",
                "internalType": "struct InventoryEntity[]",
                "components": [
                  {
                    "name": "entityId",
                    "type": "bytes32",
                    "internalType": "EntityId"
                  },
                  {
                    "name": "mass",
                    "type": "uint128",
                    "internalType": "uint128"
                  }
                ]
              }
            ]
          },
          {
            "name": "chipSystemId",
            "type": "bytes32",
            "internalType": "ResourceId"
          },
          {
            "name": "mass",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "energy",
            "type": "tuple",
            "internalType": "struct EnergyData",
            "components": [
              {
                "name": "lastUpdatedTime",
                "type": "uint128",
                "internalType": "uint128"
              },
              {
                "name": "energy",
                "type": "uint128",
                "internalType": "uint128"
              },
              {
                "name": "drainRate",
                "type": "uint128",
                "internalType": "uint128"
              },
              {
                "name": "accDepletedTime",
                "type": "uint128",
                "internalType": "uint128"
              }
            ]
          }
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getField",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      },
      {
        "name": "fieldIndex",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "fieldLayout",
        "type": "bytes32",
        "internalType": "FieldLayout"
      }
    ],
    "outputs": [
      {
        "name": "data",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getField",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      },
      {
        "name": "fieldIndex",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "outputs": [
      {
        "name": "data",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getFieldLayout",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      }
    ],
    "outputs": [
      {
        "name": "fieldLayout",
        "type": "bytes32",
        "internalType": "FieldLayout"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getFieldLength",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      },
      {
        "name": "fieldIndex",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "fieldLayout",
        "type": "bytes32",
        "internalType": "FieldLayout"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getFieldLength",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      },
      {
        "name": "fieldIndex",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getKeySchema",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      }
    ],
    "outputs": [
      {
        "name": "keySchema",
        "type": "bytes32",
        "internalType": "Schema"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getMultipleEntityData",
    "inputs": [
      {
        "name": "entityIds",
        "type": "bytes32[]",
        "internalType": "EntityId[]"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple[]",
        "internalType": "struct EntityData[]",
        "components": [
          {
            "name": "entityId",
            "type": "bytes32",
            "internalType": "EntityId"
          },
          {
            "name": "baseEntityId",
            "type": "bytes32",
            "internalType": "EntityId"
          },
          {
            "name": "objectTypeId",
            "type": "uint16",
            "internalType": "ObjectTypeId"
          },
          {
            "name": "position",
            "type": "uint96",
            "internalType": "Vec3"
          },
          {
            "name": "orientation",
            "type": "uint8",
            "internalType": "enum Direction"
          },
          {
            "name": "inventory",
            "type": "tuple[]",
            "internalType": "struct InventoryObject[]",
            "components": [
              {
                "name": "objectTypeId",
                "type": "uint16",
                "internalType": "ObjectTypeId"
              },
              {
                "name": "numObjects",
                "type": "uint16",
                "internalType": "uint16"
              },
              {
                "name": "inventoryEntities",
                "type": "tuple[]",
                "internalType": "struct InventoryEntity[]",
                "components": [
                  {
                    "name": "entityId",
                    "type": "bytes32",
                    "internalType": "EntityId"
                  },
                  {
                    "name": "mass",
                    "type": "uint128",
                    "internalType": "uint128"
                  }
                ]
              }
            ]
          },
          {
            "name": "chipSystemId",
            "type": "bytes32",
            "internalType": "ResourceId"
          },
          {
            "name": "mass",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "energy",
            "type": "tuple",
            "internalType": "struct EnergyData",
            "components": [
              {
                "name": "lastUpdatedTime",
                "type": "uint128",
                "internalType": "uint128"
              },
              {
                "name": "energy",
                "type": "uint128",
                "internalType": "uint128"
              },
              {
                "name": "drainRate",
                "type": "uint128",
                "internalType": "uint128"
              },
              {
                "name": "accDepletedTime",
                "type": "uint128",
                "internalType": "uint128"
              }
            ]
          }
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getMultipleEntityDataAtCoord",
    "inputs": [
      {
        "name": "coord",
        "type": "uint96[]",
        "internalType": "Vec3[]"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple[]",
        "internalType": "struct EntityData[]",
        "components": [
          {
            "name": "entityId",
            "type": "bytes32",
            "internalType": "EntityId"
          },
          {
            "name": "baseEntityId",
            "type": "bytes32",
            "internalType": "EntityId"
          },
          {
            "name": "objectTypeId",
            "type": "uint16",
            "internalType": "ObjectTypeId"
          },
          {
            "name": "position",
            "type": "uint96",
            "internalType": "Vec3"
          },
          {
            "name": "orientation",
            "type": "uint8",
            "internalType": "enum Direction"
          },
          {
            "name": "inventory",
            "type": "tuple[]",
            "internalType": "struct InventoryObject[]",
            "components": [
              {
                "name": "objectTypeId",
                "type": "uint16",
                "internalType": "ObjectTypeId"
              },
              {
                "name": "numObjects",
                "type": "uint16",
                "internalType": "uint16"
              },
              {
                "name": "inventoryEntities",
                "type": "tuple[]",
                "internalType": "struct InventoryEntity[]",
                "components": [
                  {
                    "name": "entityId",
                    "type": "bytes32",
                    "internalType": "EntityId"
                  },
                  {
                    "name": "mass",
                    "type": "uint128",
                    "internalType": "uint128"
                  }
                ]
              }
            ]
          },
          {
            "name": "chipSystemId",
            "type": "bytes32",
            "internalType": "ResourceId"
          },
          {
            "name": "mass",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "energy",
            "type": "tuple",
            "internalType": "struct EnergyData",
            "components": [
              {
                "name": "lastUpdatedTime",
                "type": "uint128",
                "internalType": "uint128"
              },
              {
                "name": "energy",
                "type": "uint128",
                "internalType": "uint128"
              },
              {
                "name": "drainRate",
                "type": "uint128",
                "internalType": "uint128"
              },
              {
                "name": "accDepletedTime",
                "type": "uint128",
                "internalType": "uint128"
              }
            ]
          }
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getPlayerEntityData",
    "inputs": [
      {
        "name": "player",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple",
        "internalType": "struct PlayerEntityData",
        "components": [
          {
            "name": "playerAddress",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "bedEntityId",
            "type": "bytes32",
            "internalType": "EntityId"
          },
          {
            "name": "equippedEntityId",
            "type": "bytes32",
            "internalType": "EntityId"
          },
          {
            "name": "lastActionTime",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "entityData",
            "type": "tuple",
            "internalType": "struct EntityData",
            "components": [
              {
                "name": "entityId",
                "type": "bytes32",
                "internalType": "EntityId"
              },
              {
                "name": "baseEntityId",
                "type": "bytes32",
                "internalType": "EntityId"
              },
              {
                "name": "objectTypeId",
                "type": "uint16",
                "internalType": "ObjectTypeId"
              },
              {
                "name": "position",
                "type": "uint96",
                "internalType": "Vec3"
              },
              {
                "name": "orientation",
                "type": "uint8",
                "internalType": "enum Direction"
              },
              {
                "name": "inventory",
                "type": "tuple[]",
                "internalType": "struct InventoryObject[]",
                "components": [
                  {
                    "name": "objectTypeId",
                    "type": "uint16",
                    "internalType": "ObjectTypeId"
                  },
                  {
                    "name": "numObjects",
                    "type": "uint16",
                    "internalType": "uint16"
                  },
                  {
                    "name": "inventoryEntities",
                    "type": "tuple[]",
                    "internalType": "struct InventoryEntity[]",
                    "components": [
                      {
                        "name": "entityId",
                        "type": "bytes32",
                        "internalType": "EntityId"
                      },
                      {
                        "name": "mass",
                        "type": "uint128",
                        "internalType": "uint128"
                      }
                    ]
                  }
                ]
              },
              {
                "name": "chipSystemId",
                "type": "bytes32",
                "internalType": "ResourceId"
              },
              {
                "name": "mass",
                "type": "uint256",
                "internalType": "uint256"
              },
              {
                "name": "energy",
                "type": "tuple",
                "internalType": "struct EnergyData",
                "components": [
                  {
                    "name": "lastUpdatedTime",
                    "type": "uint128",
                    "internalType": "uint128"
                  },
                  {
                    "name": "energy",
                    "type": "uint128",
                    "internalType": "uint128"
                  },
                  {
                    "name": "drainRate",
                    "type": "uint128",
                    "internalType": "uint128"
                  },
                  {
                    "name": "accDepletedTime",
                    "type": "uint128",
                    "internalType": "uint128"
                  }
                ]
              }
            ]
          }
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getPlayersEntityData",
    "inputs": [
      {
        "name": "players",
        "type": "address[]",
        "internalType": "address[]"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple[]",
        "internalType": "struct PlayerEntityData[]",
        "components": [
          {
            "name": "playerAddress",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "bedEntityId",
            "type": "bytes32",
            "internalType": "EntityId"
          },
          {
            "name": "equippedEntityId",
            "type": "bytes32",
            "internalType": "EntityId"
          },
          {
            "name": "lastActionTime",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "entityData",
            "type": "tuple",
            "internalType": "struct EntityData",
            "components": [
              {
                "name": "entityId",
                "type": "bytes32",
                "internalType": "EntityId"
              },
              {
                "name": "baseEntityId",
                "type": "bytes32",
                "internalType": "EntityId"
              },
              {
                "name": "objectTypeId",
                "type": "uint16",
                "internalType": "ObjectTypeId"
              },
              {
                "name": "position",
                "type": "uint96",
                "internalType": "Vec3"
              },
              {
                "name": "orientation",
                "type": "uint8",
                "internalType": "enum Direction"
              },
              {
                "name": "inventory",
                "type": "tuple[]",
                "internalType": "struct InventoryObject[]",
                "components": [
                  {
                    "name": "objectTypeId",
                    "type": "uint16",
                    "internalType": "ObjectTypeId"
                  },
                  {
                    "name": "numObjects",
                    "type": "uint16",
                    "internalType": "uint16"
                  },
                  {
                    "name": "inventoryEntities",
                    "type": "tuple[]",
                    "internalType": "struct InventoryEntity[]",
                    "components": [
                      {
                        "name": "entityId",
                        "type": "bytes32",
                        "internalType": "EntityId"
                      },
                      {
                        "name": "mass",
                        "type": "uint128",
                        "internalType": "uint128"
                      }
                    ]
                  }
                ]
              },
              {
                "name": "chipSystemId",
                "type": "bytes32",
                "internalType": "ResourceId"
              },
              {
                "name": "mass",
                "type": "uint256",
                "internalType": "uint256"
              },
              {
                "name": "energy",
                "type": "tuple",
                "internalType": "struct EnergyData",
                "components": [
                  {
                    "name": "lastUpdatedTime",
                    "type": "uint128",
                    "internalType": "uint128"
                  },
                  {
                    "name": "energy",
                    "type": "uint128",
                    "internalType": "uint128"
                  },
                  {
                    "name": "drainRate",
                    "type": "uint128",
                    "internalType": "uint128"
                  },
                  {
                    "name": "accDepletedTime",
                    "type": "uint128",
                    "internalType": "uint128"
                  }
                ]
              }
            ]
          }
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getRandomSpawnCoord",
    "inputs": [
      {
        "name": "blockNumber",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "sender",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [
      {
        "name": "spawnCoord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getRecord",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      },
      {
        "name": "fieldLayout",
        "type": "bytes32",
        "internalType": "FieldLayout"
      }
    ],
    "outputs": [
      {
        "name": "staticData",
        "type": "bytes",
        "internalType": "bytes"
      },
      {
        "name": "encodedLengths",
        "type": "bytes32",
        "internalType": "EncodedLengths"
      },
      {
        "name": "dynamicData",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getRecord",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      }
    ],
    "outputs": [
      {
        "name": "staticData",
        "type": "bytes",
        "internalType": "bytes"
      },
      {
        "name": "encodedLengths",
        "type": "bytes32",
        "internalType": "EncodedLengths"
      },
      {
        "name": "dynamicData",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getStaticField",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      },
      {
        "name": "fieldIndex",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "fieldLayout",
        "type": "bytes32",
        "internalType": "FieldLayout"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getValidSpawnY",
    "inputs": [
      {
        "name": "spawnCoordCandidate",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "outputs": [
      {
        "name": "spawnCoord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getValueSchema",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      }
    ],
    "outputs": [
      {
        "name": "valueSchema",
        "type": "bytes32",
        "internalType": "Schema"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "grantAccess",
    "inputs": [
      {
        "name": "resourceId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "grantee",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "growSeed",
    "inputs": [
      {
        "name": "coord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "hitForceField",
    "inputs": [
      {
        "name": "entityCoord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "initialize",
    "inputs": [
      {
        "name": "initModule",
        "type": "address",
        "internalType": "contract IModule"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "installModule",
    "inputs": [
      {
        "name": "module",
        "type": "address",
        "internalType": "contract IModule"
      },
      {
        "name": "encodedArgs",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "installRootModule",
    "inputs": [
      {
        "name": "module",
        "type": "address",
        "internalType": "contract IModule"
      },
      {
        "name": "encodedArgs",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "isValidSpawn",
    "inputs": [
      {
        "name": "spawnCoord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "jumpBuild",
    "inputs": [
      {
        "name": "buildObjectTypeId",
        "type": "uint16",
        "internalType": "ObjectTypeId"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "jumpBuildWithDirection",
    "inputs": [
      {
        "name": "buildObjectTypeId",
        "type": "uint16",
        "internalType": "ObjectTypeId"
      },
      {
        "name": "direction",
        "type": "uint8",
        "internalType": "enum Direction"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "jumpBuildWithExtraData",
    "inputs": [
      {
        "name": "buildObjectTypeId",
        "type": "uint16",
        "internalType": "ObjectTypeId"
      },
      {
        "name": "direction",
        "type": "uint8",
        "internalType": "enum Direction"
      },
      {
        "name": "extraData",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "mine",
    "inputs": [
      {
        "name": "coord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "mineUntilDestroyed",
    "inputs": [
      {
        "name": "coord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "mineUntilDestroyedWithExtraData",
    "inputs": [
      {
        "name": "coord",
        "type": "uint96",
        "internalType": "Vec3"
      },
      {
        "name": "extraData",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "mineWithExtraData",
    "inputs": [
      {
        "name": "coord",
        "type": "uint96",
        "internalType": "Vec3"
      },
      {
        "name": "extraData",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "EntityId"
      }
    ],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "move",
    "inputs": [
      {
        "name": "newCoords",
        "type": "uint96[]",
        "internalType": "Vec3[]"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "moveDirections",
    "inputs": [
      {
        "name": "directions",
        "type": "uint8[]",
        "internalType": "enum Direction[]"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "oreChunkCommit",
    "inputs": [
      {
        "name": "chunkCoord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "pickup",
    "inputs": [
      {
        "name": "pickupObjectTypeId",
        "type": "uint16",
        "internalType": "ObjectTypeId"
      },
      {
        "name": "numToPickup",
        "type": "uint16",
        "internalType": "uint16"
      },
      {
        "name": "coord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "pickupAll",
    "inputs": [
      {
        "name": "coord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "pickupMultiple",
    "inputs": [
      {
        "name": "pickupObjects",
        "type": "tuple[]",
        "internalType": "struct PickupData[]",
        "components": [
          {
            "name": "objectTypeId",
            "type": "uint16",
            "internalType": "ObjectTypeId"
          },
          {
            "name": "numToPickup",
            "type": "uint16",
            "internalType": "uint16"
          }
        ]
      },
      {
        "name": "pickupTools",
        "type": "bytes32[]",
        "internalType": "EntityId[]"
      },
      {
        "name": "coord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "pickupTool",
    "inputs": [
      {
        "name": "toolEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "coord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "popFromDynamicField",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      },
      {
        "name": "dynamicFieldIndex",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "byteLengthToPop",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "powerMachine",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "numBattery",
        "type": "uint16",
        "internalType": "uint16"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "pushToDynamicField",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      },
      {
        "name": "dynamicFieldIndex",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "dataToPush",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "randomSpawn",
    "inputs": [
      {
        "name": "blockNumber",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "y",
        "type": "int32",
        "internalType": "int32"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "EntityId"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "registerDelegation",
    "inputs": [
      {
        "name": "delegatee",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "delegationControlId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "initCallData",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "registerFunctionSelector",
    "inputs": [
      {
        "name": "systemId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "systemFunctionSignature",
        "type": "string",
        "internalType": "string"
      }
    ],
    "outputs": [
      {
        "name": "worldFunctionSelector",
        "type": "bytes4",
        "internalType": "bytes4"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "registerNamespace",
    "inputs": [
      {
        "name": "namespaceId",
        "type": "bytes32",
        "internalType": "ResourceId"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "registerNamespaceDelegation",
    "inputs": [
      {
        "name": "namespaceId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "delegationControlId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "initCallData",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "registerRootFunctionSelector",
    "inputs": [
      {
        "name": "systemId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "worldFunctionSignature",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "systemFunctionSignature",
        "type": "string",
        "internalType": "string"
      }
    ],
    "outputs": [
      {
        "name": "worldFunctionSelector",
        "type": "bytes4",
        "internalType": "bytes4"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "registerStoreHook",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "hookAddress",
        "type": "address",
        "internalType": "contract IStoreHook"
      },
      {
        "name": "enabledHooksBitmap",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "registerSystem",
    "inputs": [
      {
        "name": "systemId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "system",
        "type": "address",
        "internalType": "contract System"
      },
      {
        "name": "publicAccess",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "registerSystemHook",
    "inputs": [
      {
        "name": "systemId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "hookAddress",
        "type": "address",
        "internalType": "contract ISystemHook"
      },
      {
        "name": "enabledHooksBitmap",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "registerTable",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "fieldLayout",
        "type": "bytes32",
        "internalType": "FieldLayout"
      },
      {
        "name": "keySchema",
        "type": "bytes32",
        "internalType": "Schema"
      },
      {
        "name": "valueSchema",
        "type": "bytes32",
        "internalType": "Schema"
      },
      {
        "name": "keyNames",
        "type": "string[]",
        "internalType": "string[]"
      },
      {
        "name": "fieldNames",
        "type": "string[]",
        "internalType": "string[]"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "removeDeadPlayerFromBed",
    "inputs": [
      {
        "name": "playerEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "dropCoord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "renounceOwnership",
    "inputs": [
      {
        "name": "namespaceId",
        "type": "bytes32",
        "internalType": "ResourceId"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "respawnOre",
    "inputs": [
      {
        "name": "blockNumber",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "revokeAccess",
    "inputs": [
      {
        "name": "resourceId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "grantee",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setDisplayContent",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "content",
        "type": "tuple",
        "internalType": "struct DisplayContentData",
        "components": [
          {
            "name": "contentType",
            "type": "uint8",
            "internalType": "enum DisplayContentType"
          },
          {
            "name": "content",
            "type": "bytes",
            "internalType": "bytes"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setDynamicField",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      },
      {
        "name": "dynamicFieldIndex",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "data",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setField",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      },
      {
        "name": "fieldIndex",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "data",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setField",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      },
      {
        "name": "fieldIndex",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "data",
        "type": "bytes",
        "internalType": "bytes"
      },
      {
        "name": "fieldLayout",
        "type": "bytes32",
        "internalType": "FieldLayout"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setRecord",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      },
      {
        "name": "staticData",
        "type": "bytes",
        "internalType": "bytes"
      },
      {
        "name": "encodedLengths",
        "type": "bytes32",
        "internalType": "EncodedLengths"
      },
      {
        "name": "dynamicData",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setStaticField",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      },
      {
        "name": "fieldIndex",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "data",
        "type": "bytes",
        "internalType": "bytes"
      },
      {
        "name": "fieldLayout",
        "type": "bytes32",
        "internalType": "FieldLayout"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "sleep",
    "inputs": [
      {
        "name": "bedEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "sleepWithExtraData",
    "inputs": [
      {
        "name": "bedEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "extraData",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "spawn",
    "inputs": [
      {
        "name": "spawnTileEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "spawnCoord",
        "type": "uint96",
        "internalType": "Vec3"
      },
      {
        "name": "extraData",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "EntityId"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "spliceDynamicData",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      },
      {
        "name": "dynamicFieldIndex",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "startWithinField",
        "type": "uint40",
        "internalType": "uint40"
      },
      {
        "name": "deleteCount",
        "type": "uint40",
        "internalType": "uint40"
      },
      {
        "name": "data",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "spliceStaticData",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      },
      {
        "name": "start",
        "type": "uint48",
        "internalType": "uint48"
      },
      {
        "name": "data",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "storeVersion",
    "inputs": [],
    "outputs": [
      {
        "name": "version",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "till",
    "inputs": [
      {
        "name": "coord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "transfer",
    "inputs": [
      {
        "name": "chestEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "isDeposit",
        "type": "bool",
        "internalType": "bool"
      },
      {
        "name": "transferObjectTypeId",
        "type": "uint16",
        "internalType": "ObjectTypeId"
      },
      {
        "name": "numToTransfer",
        "type": "uint16",
        "internalType": "uint16"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "transferBalanceToAddress",
    "inputs": [
      {
        "name": "fromNamespaceId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "toAddress",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "amount",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "transferBalanceToNamespace",
    "inputs": [
      {
        "name": "fromNamespaceId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "toNamespaceId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "amount",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "transferOwnership",
    "inputs": [
      {
        "name": "namespaceId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "newOwner",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "transferTool",
    "inputs": [
      {
        "name": "chestEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "isDeposit",
        "type": "bool",
        "internalType": "bool"
      },
      {
        "name": "toolEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "transferToolWithExtraData",
    "inputs": [
      {
        "name": "chestEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "isDeposit",
        "type": "bool",
        "internalType": "bool"
      },
      {
        "name": "toolEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "extraData",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "transferTools",
    "inputs": [
      {
        "name": "chestEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "isDeposit",
        "type": "bool",
        "internalType": "bool"
      },
      {
        "name": "toolEntityIds",
        "type": "bytes32[]",
        "internalType": "EntityId[]"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "transferToolsWithExtraData",
    "inputs": [
      {
        "name": "chestEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "isDeposit",
        "type": "bool",
        "internalType": "bool"
      },
      {
        "name": "toolEntityIds",
        "type": "bytes32[]",
        "internalType": "EntityId[]"
      },
      {
        "name": "extraData",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "transferWithExtraData",
    "inputs": [
      {
        "name": "chestEntityId",
        "type": "bytes32",
        "internalType": "EntityId"
      },
      {
        "name": "isDeposit",
        "type": "bool",
        "internalType": "bool"
      },
      {
        "name": "transferObjectTypeId",
        "type": "uint16",
        "internalType": "ObjectTypeId"
      },
      {
        "name": "numToTransfer",
        "type": "uint16",
        "internalType": "uint16"
      },
      {
        "name": "extraData",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "unequip",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "unregisterDelegation",
    "inputs": [
      {
        "name": "delegatee",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "unregisterNamespaceDelegation",
    "inputs": [
      {
        "name": "namespaceId",
        "type": "bytes32",
        "internalType": "ResourceId"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "unregisterStoreHook",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "hookAddress",
        "type": "address",
        "internalType": "contract IStoreHook"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "unregisterSystemHook",
    "inputs": [
      {
        "name": "systemId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "hookAddress",
        "type": "address",
        "internalType": "contract ISystemHook"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "validateSpanningTree",
    "inputs": [
      {
        "name": "boundaryFragments",
        "type": "uint96[]",
        "internalType": "Vec3[]"
      },
      {
        "name": "len",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "parents",
        "type": "uint256[]",
        "internalType": "uint256[]"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "pure"
  },
  {
    "type": "function",
    "name": "wakeup",
    "inputs": [
      {
        "name": "spawnCoord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "wakeupWithExtraData",
    "inputs": [
      {
        "name": "spawnCoord",
        "type": "uint96",
        "internalType": "Vec3"
      },
      {
        "name": "extraData",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "wetFarmland",
    "inputs": [
      {
        "name": "coord",
        "type": "uint96",
        "internalType": "Vec3"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "worldVersion",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "event",
    "name": "HelloStore",
    "inputs": [
      {
        "name": "storeVersion",
        "type": "bytes32",
        "indexed": true,
        "internalType": "bytes32"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "HelloWorld",
    "inputs": [
      {
        "name": "worldVersion",
        "type": "bytes32",
        "indexed": true,
        "internalType": "bytes32"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "Store_DeleteRecord",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "indexed": true,
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "indexed": false,
        "internalType": "bytes32[]"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "Store_SetRecord",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "indexed": true,
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "indexed": false,
        "internalType": "bytes32[]"
      },
      {
        "name": "staticData",
        "type": "bytes",
        "indexed": false,
        "internalType": "bytes"
      },
      {
        "name": "encodedLengths",
        "type": "bytes32",
        "indexed": false,
        "internalType": "EncodedLengths"
      },
      {
        "name": "dynamicData",
        "type": "bytes",
        "indexed": false,
        "internalType": "bytes"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "Store_SpliceDynamicData",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "indexed": true,
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "indexed": false,
        "internalType": "bytes32[]"
      },
      {
        "name": "dynamicFieldIndex",
        "type": "uint8",
        "indexed": false,
        "internalType": "uint8"
      },
      {
        "name": "start",
        "type": "uint48",
        "indexed": false,
        "internalType": "uint48"
      },
      {
        "name": "deleteCount",
        "type": "uint40",
        "indexed": false,
        "internalType": "uint40"
      },
      {
        "name": "encodedLengths",
        "type": "bytes32",
        "indexed": false,
        "internalType": "EncodedLengths"
      },
      {
        "name": "data",
        "type": "bytes",
        "indexed": false,
        "internalType": "bytes"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "Store_SpliceStaticData",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "indexed": true,
        "internalType": "ResourceId"
      },
      {
        "name": "keyTuple",
        "type": "bytes32[]",
        "indexed": false,
        "internalType": "bytes32[]"
      },
      {
        "name": "start",
        "type": "uint48",
        "indexed": false,
        "internalType": "uint48"
      },
      {
        "name": "data",
        "type": "bytes",
        "indexed": false,
        "internalType": "bytes"
      }
    ],
    "anonymous": false
  },
  {
    "type": "error",
    "name": "EncodedLengths_InvalidLength",
    "inputs": [
      {
        "name": "length",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "FieldLayout_Empty",
    "inputs": []
  },
  {
    "type": "error",
    "name": "FieldLayout_InvalidStaticDataLength",
    "inputs": [
      {
        "name": "staticDataLength",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "computedStaticDataLength",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "FieldLayout_StaticLengthDoesNotFitInAWord",
    "inputs": [
      {
        "name": "index",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "FieldLayout_StaticLengthIsNotZero",
    "inputs": [
      {
        "name": "index",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "FieldLayout_StaticLengthIsZero",
    "inputs": [
      {
        "name": "index",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "FieldLayout_TooManyDynamicFields",
    "inputs": [
      {
        "name": "numFields",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "maxFields",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "FieldLayout_TooManyFields",
    "inputs": [
      {
        "name": "numFields",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "maxFields",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "Module_AlreadyInstalled",
    "inputs": []
  },
  {
    "type": "error",
    "name": "Module_MissingDependency",
    "inputs": [
      {
        "name": "dependency",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "Module_NonRootInstallNotSupported",
    "inputs": []
  },
  {
    "type": "error",
    "name": "Module_RootInstallNotSupported",
    "inputs": []
  },
  {
    "type": "error",
    "name": "Schema_InvalidLength",
    "inputs": [
      {
        "name": "length",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "Schema_StaticTypeAfterDynamicType",
    "inputs": []
  },
  {
    "type": "error",
    "name": "Slice_OutOfBounds",
    "inputs": [
      {
        "name": "data",
        "type": "bytes",
        "internalType": "bytes"
      },
      {
        "name": "start",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "end",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "Store_IndexOutOfBounds",
    "inputs": [
      {
        "name": "length",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "accessedIndex",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "Store_InvalidBounds",
    "inputs": [
      {
        "name": "start",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "end",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "Store_InvalidFieldNamesLength",
    "inputs": [
      {
        "name": "expected",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "received",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "Store_InvalidKeyNamesLength",
    "inputs": [
      {
        "name": "expected",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "received",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "Store_InvalidResourceType",
    "inputs": [
      {
        "name": "expected",
        "type": "bytes2",
        "internalType": "bytes2"
      },
      {
        "name": "resourceId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "resourceIdString",
        "type": "string",
        "internalType": "string"
      }
    ]
  },
  {
    "type": "error",
    "name": "Store_InvalidSplice",
    "inputs": [
      {
        "name": "startWithinField",
        "type": "uint40",
        "internalType": "uint40"
      },
      {
        "name": "deleteCount",
        "type": "uint40",
        "internalType": "uint40"
      },
      {
        "name": "fieldLength",
        "type": "uint40",
        "internalType": "uint40"
      }
    ]
  },
  {
    "type": "error",
    "name": "Store_InvalidStaticDataLength",
    "inputs": [
      {
        "name": "expected",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "received",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "Store_InvalidValueSchemaDynamicLength",
    "inputs": [
      {
        "name": "expected",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "received",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "Store_InvalidValueSchemaLength",
    "inputs": [
      {
        "name": "expected",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "received",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "Store_InvalidValueSchemaStaticLength",
    "inputs": [
      {
        "name": "expected",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "received",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "Store_TableAlreadyExists",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "tableIdString",
        "type": "string",
        "internalType": "string"
      }
    ]
  },
  {
    "type": "error",
    "name": "Store_TableNotFound",
    "inputs": [
      {
        "name": "tableId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "tableIdString",
        "type": "string",
        "internalType": "string"
      }
    ]
  },
  {
    "type": "error",
    "name": "World_AccessDenied",
    "inputs": [
      {
        "name": "resource",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "caller",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "World_AlreadyInitialized",
    "inputs": []
  },
  {
    "type": "error",
    "name": "World_CallbackNotAllowed",
    "inputs": [
      {
        "name": "functionSelector",
        "type": "bytes4",
        "internalType": "bytes4"
      }
    ]
  },
  {
    "type": "error",
    "name": "World_DelegationNotFound",
    "inputs": [
      {
        "name": "delegator",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "delegatee",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "World_FunctionSelectorAlreadyExists",
    "inputs": [
      {
        "name": "functionSelector",
        "type": "bytes4",
        "internalType": "bytes4"
      }
    ]
  },
  {
    "type": "error",
    "name": "World_FunctionSelectorNotFound",
    "inputs": [
      {
        "name": "functionSelector",
        "type": "bytes4",
        "internalType": "bytes4"
      }
    ]
  },
  {
    "type": "error",
    "name": "World_InsufficientBalance",
    "inputs": [
      {
        "name": "balance",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "amount",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "World_InterfaceNotSupported",
    "inputs": [
      {
        "name": "contractAddress",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "interfaceId",
        "type": "bytes4",
        "internalType": "bytes4"
      }
    ]
  },
  {
    "type": "error",
    "name": "World_InvalidNamespace",
    "inputs": [
      {
        "name": "namespace",
        "type": "bytes14",
        "internalType": "bytes14"
      }
    ]
  },
  {
    "type": "error",
    "name": "World_InvalidResourceId",
    "inputs": [
      {
        "name": "resourceId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "resourceIdString",
        "type": "string",
        "internalType": "string"
      }
    ]
  },
  {
    "type": "error",
    "name": "World_InvalidResourceType",
    "inputs": [
      {
        "name": "expected",
        "type": "bytes2",
        "internalType": "bytes2"
      },
      {
        "name": "resourceId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "resourceIdString",
        "type": "string",
        "internalType": "string"
      }
    ]
  },
  {
    "type": "error",
    "name": "World_ResourceAlreadyExists",
    "inputs": [
      {
        "name": "resourceId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "resourceIdString",
        "type": "string",
        "internalType": "string"
      }
    ]
  },
  {
    "type": "error",
    "name": "World_ResourceNotFound",
    "inputs": [
      {
        "name": "resourceId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "resourceIdString",
        "type": "string",
        "internalType": "string"
      }
    ]
  },
  {
    "type": "error",
    "name": "World_SystemAlreadyExists",
    "inputs": [
      {
        "name": "system",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "World_UnlimitedDelegationNotAllowed",
    "inputs": []
  }
];

export default abi;
