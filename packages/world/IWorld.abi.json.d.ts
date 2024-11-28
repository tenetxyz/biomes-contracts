declare const abi: [
  {
    "type": "function",
    "name": "Air",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "Flora",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "Ores",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "Ores",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      },
      {
        "name": "randomNumber",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "Ores",
    "inputs": [
      {
        "name": "x",
        "type": "int16",
        "internalType": "int16"
      },
      {
        "name": "y",
        "type": "int16",
        "internalType": "int16"
      },
      {
        "name": "z",
        "type": "int16",
        "internalType": "int16"
      },
      {
        "name": "height",
        "type": "int16",
        "internalType": "int16"
      },
      {
        "name": "biome",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "distanceFromHeight",
        "type": "int16",
        "internalType": "int16"
      },
      {
        "name": "randomNumber",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "TerrainBlocks",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "Trees",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "Water",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "activate",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
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
    "name": "addSpawn",
    "inputs": [
      {
        "name": "lowerSouthwestCorner",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      },
      {
        "name": "size",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
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
        "internalType": "bytes32"
      },
      {
        "name": "chipAddress",
        "type": "address",
        "internalType": "address"
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
    "name": "attachChip",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "chipAddress",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
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
        "name": "objectTypeId",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
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
        "internalType": "bytes32"
      }
    ],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "build",
    "inputs": [
      {
        "name": "objectTypeId",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "bytes32"
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
    "name": "commitOre",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
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
      },
      {
        "name": "stationEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "craftChipBattery",
    "inputs": [
      {
        "name": "numBatteries",
        "type": "uint16",
        "internalType": "uint16"
      },
      {
        "name": "stationEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
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
    "name": "deleteAllUserHooks",
    "inputs": [
      {
        "name": "player",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "systemId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "callDataHash",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
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
        "internalType": "bytes32"
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
        "internalType": "bytes32"
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
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "numToDrop",
        "type": "uint16",
        "internalType": "uint16"
      },
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
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
        "internalType": "bytes32"
      },
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
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
        "internalType": "bytes32"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "fillTerrainCache",
    "inputs": [
      {
        "name": "lowerSouthwestCorner",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      },
      {
        "name": "size",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "fillTerrainCache",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple[]",
        "internalType": "struct VoxelCoord[]",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "fillTerrainCache",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "getBlockEntityData",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple",
        "internalType": "struct BlockEntityData",
        "components": [
          {
            "name": "entityId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "baseEntityId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "objectTypeId",
            "type": "uint8",
            "internalType": "uint8"
          },
          {
            "name": "position",
            "type": "tuple",
            "internalType": "struct VoxelCoord",
            "components": [
              {
                "name": "x",
                "type": "int16",
                "internalType": "int16"
              },
              {
                "name": "y",
                "type": "int16",
                "internalType": "int16"
              },
              {
                "name": "z",
                "type": "int16",
                "internalType": "int16"
              }
            ]
          },
          {
            "name": "inventory",
            "type": "tuple[]",
            "internalType": "struct InventoryObject[]",
            "components": [
              {
                "name": "objectTypeId",
                "type": "uint8",
                "internalType": "uint8"
              },
              {
                "name": "numObjects",
                "type": "uint16",
                "internalType": "uint16"
              },
              {
                "name": "tools",
                "type": "tuple[]",
                "internalType": "struct InventoryTool[]",
                "components": [
                  {
                    "name": "entityId",
                    "type": "bytes32",
                    "internalType": "bytes32"
                  },
                  {
                    "name": "numUsesLeft",
                    "type": "uint24",
                    "internalType": "uint24"
                  }
                ]
              }
            ]
          },
          {
            "name": "chip",
            "type": "tuple",
            "internalType": "struct ChipData",
            "components": [
              {
                "name": "chipAddress",
                "type": "address",
                "internalType": "address"
              },
              {
                "name": "batteryLevel",
                "type": "uint256",
                "internalType": "uint256"
              },
              {
                "name": "lastUpdatedTime",
                "type": "uint256",
                "internalType": "uint256"
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
    "name": "getBlocksEntityData",
    "inputs": [
      {
        "name": "entityIds",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple[]",
        "internalType": "struct BlockEntityData[]",
        "components": [
          {
            "name": "entityId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "baseEntityId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "objectTypeId",
            "type": "uint8",
            "internalType": "uint8"
          },
          {
            "name": "position",
            "type": "tuple",
            "internalType": "struct VoxelCoord",
            "components": [
              {
                "name": "x",
                "type": "int16",
                "internalType": "int16"
              },
              {
                "name": "y",
                "type": "int16",
                "internalType": "int16"
              },
              {
                "name": "z",
                "type": "int16",
                "internalType": "int16"
              }
            ]
          },
          {
            "name": "inventory",
            "type": "tuple[]",
            "internalType": "struct InventoryObject[]",
            "components": [
              {
                "name": "objectTypeId",
                "type": "uint8",
                "internalType": "uint8"
              },
              {
                "name": "numObjects",
                "type": "uint16",
                "internalType": "uint16"
              },
              {
                "name": "tools",
                "type": "tuple[]",
                "internalType": "struct InventoryTool[]",
                "components": [
                  {
                    "name": "entityId",
                    "type": "bytes32",
                    "internalType": "bytes32"
                  },
                  {
                    "name": "numUsesLeft",
                    "type": "uint24",
                    "internalType": "uint24"
                  }
                ]
              }
            ]
          },
          {
            "name": "chip",
            "type": "tuple",
            "internalType": "struct ChipData",
            "components": [
              {
                "name": "chipAddress",
                "type": "address",
                "internalType": "address"
              },
              {
                "name": "batteryLevel",
                "type": "uint256",
                "internalType": "uint256"
              },
              {
                "name": "lastUpdatedTime",
                "type": "uint256",
                "internalType": "uint256"
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
    "name": "getCachedTerrainObjectTypeId",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getCoordForEntityId",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
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
        "internalType": "bytes32"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple",
        "internalType": "struct DisplayContent",
        "components": [
          {
            "name": "contentType",
            "type": "uint8",
            "internalType": "uint8"
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
        "internalType": "bytes32"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple",
        "internalType": "struct EntityData",
        "components": [
          {
            "name": "objectTypeId",
            "type": "uint8",
            "internalType": "uint8"
          },
          {
            "name": "entityId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "inventory",
            "type": "tuple[]",
            "internalType": "struct InventoryObject[]",
            "components": [
              {
                "name": "objectTypeId",
                "type": "uint8",
                "internalType": "uint8"
              },
              {
                "name": "numObjects",
                "type": "uint16",
                "internalType": "uint16"
              },
              {
                "name": "tools",
                "type": "tuple[]",
                "internalType": "struct InventoryTool[]",
                "components": [
                  {
                    "name": "entityId",
                    "type": "bytes32",
                    "internalType": "bytes32"
                  },
                  {
                    "name": "numUsesLeft",
                    "type": "uint24",
                    "internalType": "uint24"
                  }
                ]
              }
            ]
          },
          {
            "name": "position",
            "type": "tuple",
            "internalType": "struct VoxelCoord",
            "components": [
              {
                "name": "x",
                "type": "int16",
                "internalType": "int16"
              },
              {
                "name": "y",
                "type": "int16",
                "internalType": "int16"
              },
              {
                "name": "z",
                "type": "int16",
                "internalType": "int16"
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
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple",
        "internalType": "struct EntityData",
        "components": [
          {
            "name": "objectTypeId",
            "type": "uint8",
            "internalType": "uint8"
          },
          {
            "name": "entityId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "inventory",
            "type": "tuple[]",
            "internalType": "struct InventoryObject[]",
            "components": [
              {
                "name": "objectTypeId",
                "type": "uint8",
                "internalType": "uint8"
              },
              {
                "name": "numObjects",
                "type": "uint16",
                "internalType": "uint16"
              },
              {
                "name": "tools",
                "type": "tuple[]",
                "internalType": "struct InventoryTool[]",
                "components": [
                  {
                    "name": "entityId",
                    "type": "bytes32",
                    "internalType": "bytes32"
                  },
                  {
                    "name": "numUsesLeft",
                    "type": "uint24",
                    "internalType": "uint24"
                  }
                ]
              }
            ]
          },
          {
            "name": "position",
            "type": "tuple",
            "internalType": "struct VoxelCoord",
            "components": [
              {
                "name": "x",
                "type": "int16",
                "internalType": "int16"
              },
              {
                "name": "y",
                "type": "int16",
                "internalType": "int16"
              },
              {
                "name": "z",
                "type": "int16",
                "internalType": "int16"
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
    "name": "getEntityDataWithBaseEntity",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple",
        "internalType": "struct EntityDataWithBaseEntity",
        "components": [
          {
            "name": "objectTypeId",
            "type": "uint8",
            "internalType": "uint8"
          },
          {
            "name": "entityId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "baseEntityId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "inventory",
            "type": "tuple[]",
            "internalType": "struct InventoryObject[]",
            "components": [
              {
                "name": "objectTypeId",
                "type": "uint8",
                "internalType": "uint8"
              },
              {
                "name": "numObjects",
                "type": "uint16",
                "internalType": "uint16"
              },
              {
                "name": "tools",
                "type": "tuple[]",
                "internalType": "struct InventoryTool[]",
                "components": [
                  {
                    "name": "entityId",
                    "type": "bytes32",
                    "internalType": "bytes32"
                  },
                  {
                    "name": "numUsesLeft",
                    "type": "uint24",
                    "internalType": "uint24"
                  }
                ]
              }
            ]
          },
          {
            "name": "position",
            "type": "tuple",
            "internalType": "struct VoxelCoord",
            "components": [
              {
                "name": "x",
                "type": "int16",
                "internalType": "int16"
              },
              {
                "name": "y",
                "type": "int16",
                "internalType": "int16"
              },
              {
                "name": "z",
                "type": "int16",
                "internalType": "int16"
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
    "name": "getEntityDataWithBaseEntityAtCoord",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple",
        "internalType": "struct EntityDataWithBaseEntity",
        "components": [
          {
            "name": "objectTypeId",
            "type": "uint8",
            "internalType": "uint8"
          },
          {
            "name": "entityId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "baseEntityId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "inventory",
            "type": "tuple[]",
            "internalType": "struct InventoryObject[]",
            "components": [
              {
                "name": "objectTypeId",
                "type": "uint8",
                "internalType": "uint8"
              },
              {
                "name": "numObjects",
                "type": "uint16",
                "internalType": "uint16"
              },
              {
                "name": "tools",
                "type": "tuple[]",
                "internalType": "struct InventoryTool[]",
                "components": [
                  {
                    "name": "entityId",
                    "type": "bytes32",
                    "internalType": "bytes32"
                  },
                  {
                    "name": "numUsesLeft",
                    "type": "uint24",
                    "internalType": "uint24"
                  }
                ]
              }
            ]
          },
          {
            "name": "position",
            "type": "tuple",
            "internalType": "struct VoxelCoord",
            "components": [
              {
                "name": "x",
                "type": "int16",
                "internalType": "int16"
              },
              {
                "name": "y",
                "type": "int16",
                "internalType": "int16"
              },
              {
                "name": "z",
                "type": "int16",
                "internalType": "int16"
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
    "name": "getEntityIdAtCoord",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
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
    "name": "getHealth",
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
        "internalType": "struct HealthData",
        "components": [
          {
            "name": "lastUpdatedTime",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "health",
            "type": "uint16",
            "internalType": "uint16"
          }
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getInventory",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple[]",
        "internalType": "struct InventoryObject[]",
        "components": [
          {
            "name": "objectTypeId",
            "type": "uint8",
            "internalType": "uint8"
          },
          {
            "name": "numObjects",
            "type": "uint16",
            "internalType": "uint16"
          },
          {
            "name": "tools",
            "type": "tuple[]",
            "internalType": "struct InventoryTool[]",
            "components": [
              {
                "name": "entityId",
                "type": "bytes32",
                "internalType": "bytes32"
              },
              {
                "name": "numUsesLeft",
                "type": "uint24",
                "internalType": "uint24"
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
    "name": "getInventory",
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
        "type": "tuple[]",
        "internalType": "struct InventoryObject[]",
        "components": [
          {
            "name": "objectTypeId",
            "type": "uint8",
            "internalType": "uint8"
          },
          {
            "name": "numObjects",
            "type": "uint16",
            "internalType": "uint16"
          },
          {
            "name": "tools",
            "type": "tuple[]",
            "internalType": "struct InventoryTool[]",
            "components": [
              {
                "name": "entityId",
                "type": "bytes32",
                "internalType": "bytes32"
              },
              {
                "name": "numUsesLeft",
                "type": "uint24",
                "internalType": "uint24"
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
    "name": "getLastActivityTime",
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
        "type": "uint256",
        "internalType": "uint256"
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
        "type": "tuple[]",
        "internalType": "struct VoxelCoord[]",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple[]",
        "internalType": "struct EntityData[]",
        "components": [
          {
            "name": "objectTypeId",
            "type": "uint8",
            "internalType": "uint8"
          },
          {
            "name": "entityId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "inventory",
            "type": "tuple[]",
            "internalType": "struct InventoryObject[]",
            "components": [
              {
                "name": "objectTypeId",
                "type": "uint8",
                "internalType": "uint8"
              },
              {
                "name": "numObjects",
                "type": "uint16",
                "internalType": "uint16"
              },
              {
                "name": "tools",
                "type": "tuple[]",
                "internalType": "struct InventoryTool[]",
                "components": [
                  {
                    "name": "entityId",
                    "type": "bytes32",
                    "internalType": "bytes32"
                  },
                  {
                    "name": "numUsesLeft",
                    "type": "uint24",
                    "internalType": "uint24"
                  }
                ]
              }
            ]
          },
          {
            "name": "position",
            "type": "tuple",
            "internalType": "struct VoxelCoord",
            "components": [
              {
                "name": "x",
                "type": "int16",
                "internalType": "int16"
              },
              {
                "name": "y",
                "type": "int16",
                "internalType": "int16"
              },
              {
                "name": "z",
                "type": "int16",
                "internalType": "int16"
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
    "name": "getMultipleEntityDataWithBaseEntityAtCoord",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple[]",
        "internalType": "struct VoxelCoord[]",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple[]",
        "internalType": "struct EntityDataWithBaseEntity[]",
        "components": [
          {
            "name": "objectTypeId",
            "type": "uint8",
            "internalType": "uint8"
          },
          {
            "name": "entityId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "baseEntityId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "inventory",
            "type": "tuple[]",
            "internalType": "struct InventoryObject[]",
            "components": [
              {
                "name": "objectTypeId",
                "type": "uint8",
                "internalType": "uint8"
              },
              {
                "name": "numObjects",
                "type": "uint16",
                "internalType": "uint16"
              },
              {
                "name": "tools",
                "type": "tuple[]",
                "internalType": "struct InventoryTool[]",
                "components": [
                  {
                    "name": "entityId",
                    "type": "bytes32",
                    "internalType": "bytes32"
                  },
                  {
                    "name": "numUsesLeft",
                    "type": "uint24",
                    "internalType": "uint24"
                  }
                ]
              }
            ]
          },
          {
            "name": "position",
            "type": "tuple",
            "internalType": "struct VoxelCoord",
            "components": [
              {
                "name": "x",
                "type": "int16",
                "internalType": "int16"
              },
              {
                "name": "y",
                "type": "int16",
                "internalType": "int16"
              },
              {
                "name": "z",
                "type": "int16",
                "internalType": "int16"
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
    "name": "getMultipleObjectTypeIdAtCoordOrTerrain",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple[]",
        "internalType": "struct VoxelCoord[]",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint8[]",
        "internalType": "uint8[]"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getObjectTypeIdAtCoord",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getObjectTypeIdAtCoordOrTerrain",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getOptionalSystemHooks",
    "inputs": [
      {
        "name": "player",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "SystemId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "callDataHash",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [
      {
        "name": "hooks",
        "type": "bytes21[]",
        "internalType": "bytes21[]"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getPlayerCoord",
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
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
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
            "name": "entityId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "position",
            "type": "tuple",
            "internalType": "struct VoxelCoord",
            "components": [
              {
                "name": "x",
                "type": "int16",
                "internalType": "int16"
              },
              {
                "name": "y",
                "type": "int16",
                "internalType": "int16"
              },
              {
                "name": "z",
                "type": "int16",
                "internalType": "int16"
              }
            ]
          },
          {
            "name": "metadata",
            "type": "tuple",
            "internalType": "struct PlayerMetadataData",
            "components": [
              {
                "name": "isLoggedOff",
                "type": "bool",
                "internalType": "bool"
              },
              {
                "name": "lastHitTime",
                "type": "uint256",
                "internalType": "uint256"
              }
            ]
          },
          {
            "name": "equippedEntityId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "inventory",
            "type": "tuple[]",
            "internalType": "struct InventoryObject[]",
            "components": [
              {
                "name": "objectTypeId",
                "type": "uint8",
                "internalType": "uint8"
              },
              {
                "name": "numObjects",
                "type": "uint16",
                "internalType": "uint16"
              },
              {
                "name": "tools",
                "type": "tuple[]",
                "internalType": "struct InventoryTool[]",
                "components": [
                  {
                    "name": "entityId",
                    "type": "bytes32",
                    "internalType": "bytes32"
                  },
                  {
                    "name": "numUsesLeft",
                    "type": "uint24",
                    "internalType": "uint24"
                  }
                ]
              }
            ]
          },
          {
            "name": "health",
            "type": "tuple",
            "internalType": "struct HealthData",
            "components": [
              {
                "name": "lastUpdatedTime",
                "type": "uint256",
                "internalType": "uint256"
              },
              {
                "name": "health",
                "type": "uint16",
                "internalType": "uint16"
              }
            ]
          },
          {
            "name": "stamina",
            "type": "tuple",
            "internalType": "struct StaminaData",
            "components": [
              {
                "name": "lastUpdatedTime",
                "type": "uint256",
                "internalType": "uint256"
              },
              {
                "name": "stamina",
                "type": "uint32",
                "internalType": "uint32"
              }
            ]
          },
          {
            "name": "xp",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "lastActionTime",
            "type": "uint256",
            "internalType": "uint256"
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
            "name": "entityId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "position",
            "type": "tuple",
            "internalType": "struct VoxelCoord",
            "components": [
              {
                "name": "x",
                "type": "int16",
                "internalType": "int16"
              },
              {
                "name": "y",
                "type": "int16",
                "internalType": "int16"
              },
              {
                "name": "z",
                "type": "int16",
                "internalType": "int16"
              }
            ]
          },
          {
            "name": "metadata",
            "type": "tuple",
            "internalType": "struct PlayerMetadataData",
            "components": [
              {
                "name": "isLoggedOff",
                "type": "bool",
                "internalType": "bool"
              },
              {
                "name": "lastHitTime",
                "type": "uint256",
                "internalType": "uint256"
              }
            ]
          },
          {
            "name": "equippedEntityId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "inventory",
            "type": "tuple[]",
            "internalType": "struct InventoryObject[]",
            "components": [
              {
                "name": "objectTypeId",
                "type": "uint8",
                "internalType": "uint8"
              },
              {
                "name": "numObjects",
                "type": "uint16",
                "internalType": "uint16"
              },
              {
                "name": "tools",
                "type": "tuple[]",
                "internalType": "struct InventoryTool[]",
                "components": [
                  {
                    "name": "entityId",
                    "type": "bytes32",
                    "internalType": "bytes32"
                  },
                  {
                    "name": "numUsesLeft",
                    "type": "uint24",
                    "internalType": "uint24"
                  }
                ]
              }
            ]
          },
          {
            "name": "health",
            "type": "tuple",
            "internalType": "struct HealthData",
            "components": [
              {
                "name": "lastUpdatedTime",
                "type": "uint256",
                "internalType": "uint256"
              },
              {
                "name": "health",
                "type": "uint16",
                "internalType": "uint16"
              }
            ]
          },
          {
            "name": "stamina",
            "type": "tuple",
            "internalType": "struct StaminaData",
            "components": [
              {
                "name": "lastUpdatedTime",
                "type": "uint256",
                "internalType": "uint256"
              },
              {
                "name": "stamina",
                "type": "uint32",
                "internalType": "uint32"
              }
            ]
          },
          {
            "name": "xp",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "lastActionTime",
            "type": "uint256",
            "internalType": "uint256"
          }
        ]
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
    "name": "getStamina",
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
        "internalType": "struct StaminaData",
        "components": [
          {
            "name": "lastUpdatedTime",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "stamina",
            "type": "uint32",
            "internalType": "uint32"
          }
        ]
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
    "name": "getTerrainBlock",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getTerrainBlockWithRandomness",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      },
      {
        "name": "randomNumber",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getTerrainObjectTypeId",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getTerrainObjectTypeIdWithCacheSet",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "getUserDelegation",
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
    ],
    "outputs": [
      {
        "name": "delegationControlId",
        "type": "bytes32",
        "internalType": "ResourceId"
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
    "name": "hit",
    "inputs": [
      {
        "name": "hitPlayer",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "hitChip",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "hitChippedEntity",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
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
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "initDyedObjectTypes",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "initDyedRecipes",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "initHandcrafedRecipes",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "initHandcraftedObjectTypes",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "initInteractableObjectTypes",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "initInteractablesRecipes",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "initPlayerObjectTypes",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "initSpawnAreaBottom",
    "inputs": [
      {
        "name": "spawnCoord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "initSpawnAreaBottomBorder",
    "inputs": [
      {
        "name": "spawnCoord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "initSpawnAreaBottomPart2",
    "inputs": [
      {
        "name": "spawnCoord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "initSpawnAreaTop",
    "inputs": [
      {
        "name": "spawnCoord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "initSpawnAreaTopAir",
    "inputs": [
      {
        "name": "spawnCoord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "initSpawnAreaTopAirPart2",
    "inputs": [
      {
        "name": "spawnCoord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "initSpawnAreaTopPart2",
    "inputs": [
      {
        "name": "spawnCoord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "initTerrainBlockObjectTypes",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "initThermoblastObjectTypes",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "initThermoblastRecipes",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "initWorkbenchObjectTypes",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "initWorkbenchRecipes",
    "inputs": [],
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
    "name": "jumpBuild",
    "inputs": [
      {
        "name": "objectTypeId",
        "type": "uint8",
        "internalType": "uint8"
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
    "name": "jumpBuild",
    "inputs": [
      {
        "name": "objectTypeId",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "loginPlayer",
    "inputs": [
      {
        "name": "respawnCoord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "logoffPlayer",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "logoffStalePlayer",
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
    "name": "mine",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
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
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
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
    "name": "mintXP",
    "inputs": [
      {
        "name": "playerEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "initialGas",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "multiplier",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "move",
    "inputs": [
      {
        "name": "newCoords",
        "type": "tuple[]",
        "internalType": "struct VoxelCoord[]",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "onMine",
    "inputs": [
      {
        "name": "playerEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "baseEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "mineObjectTypeId",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "coords",
        "type": "tuple[]",
        "internalType": "struct VoxelCoord[]",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
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
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "numToPickup",
        "type": "uint16",
        "internalType": "uint16"
      },
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
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
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
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
            "type": "uint8",
            "internalType": "uint8"
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
        "internalType": "bytes32[]"
      },
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
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
        "internalType": "bytes32"
      },
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
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
    "name": "powerChip",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
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
    "name": "registerOptionalSystemHook",
    "inputs": [
      {
        "name": "systemId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "hookAddress",
        "type": "address",
        "internalType": "contract IOptionalSystemHook"
      },
      {
        "name": "enabledHooksBitmap",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "callDataHash",
        "type": "bytes32",
        "internalType": "bytes32"
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
    "name": "requireBuildAllowed",
    "inputs": [
      {
        "name": "playerEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "objectTypeId",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
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
    "name": "requireBuildsAllowed",
    "inputs": [
      {
        "name": "playerEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "baseEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "objectTypeId",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "coords",
        "type": "tuple[]",
        "internalType": "struct VoxelCoord[]",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
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
    "name": "requireMineAllowed",
    "inputs": [
      {
        "name": "playerEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "equippedToolDamage",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "objectTypeId",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
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
    "name": "requireMinesAllowed",
    "inputs": [
      {
        "name": "playerEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "baseEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "objectTypeId",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "coords",
        "type": "tuple[]",
        "internalType": "struct VoxelCoord[]",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
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
    "name": "revealOre",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
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
    "name": "runGravity",
    "inputs": [
      {
        "name": "playerEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "playerCoord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setBlockHash",
    "inputs": [
      {
        "name": "blockNumber",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "blockHash",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setChestOnTransferHook",
    "inputs": [
      {
        "name": "chestEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "hookAddress",
        "type": "address",
        "internalType": "address"
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
    "name": "setObjectAtCoord",
    "inputs": [
      {
        "name": "objectTypeId",
        "type": "uint8[]",
        "internalType": "uint8[]"
      },
      {
        "name": "coord",
        "type": "tuple[]",
        "internalType": "struct VoxelCoord[]",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setObjectAtCoord",
    "inputs": [
      {
        "name": "objectTypeId",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "coord",
        "type": "tuple[]",
        "internalType": "struct VoxelCoord[]",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setObjectAtCoord",
    "inputs": [
      {
        "name": "objectTypeId",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "coord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
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
    "name": "setTerrainObjectTypeIds",
    "inputs": [
      {
        "name": "lowerSouthwestCorner",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      },
      {
        "name": "size",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      },
      {
        "name": "objectTypeId",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setTerrainObjectTypeIds",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple[]",
        "internalType": "struct VoxelCoord[]",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      },
      {
        "name": "objectTypeId",
        "type": "uint8",
        "internalType": "uint8"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setTerrainObjectTypeIds",
    "inputs": [
      {
        "name": "coord",
        "type": "tuple[]",
        "internalType": "struct VoxelCoord[]",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      },
      {
        "name": "objectTypeId",
        "type": "uint8[]",
        "internalType": "uint8[]"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "spawnPlayer",
    "inputs": [
      {
        "name": "spawnCoord",
        "type": "tuple",
        "internalType": "struct VoxelCoord",
        "components": [
          {
            "name": "x",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "y",
            "type": "int16",
            "internalType": "int16"
          },
          {
            "name": "z",
            "type": "int16",
            "internalType": "int16"
          }
        ]
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "bytes32"
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
    "name": "strengthenChest",
    "inputs": [
      {
        "name": "chestEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "strengthenObjectTypeId",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "strengthenObjectTypeAmount",
        "type": "uint16",
        "internalType": "uint16"
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
        "name": "srcEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "dstEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "transferObjectTypeId",
        "type": "uint8",
        "internalType": "uint8"
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
    "name": "transfer",
    "inputs": [
      {
        "name": "srcEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "dstEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "transferObjectTypeId",
        "type": "uint8",
        "internalType": "uint8"
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
        "name": "srcEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "dstEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "toolEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
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
    "name": "transferTool",
    "inputs": [
      {
        "name": "srcEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "dstEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "toolEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
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
        "name": "srcEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "dstEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "toolEntityIds",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
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
        "name": "srcEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "dstEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "toolEntityIds",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
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
    "name": "unregisterOptionalSystemHook",
    "inputs": [
      {
        "name": "systemId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "hookAddress",
        "type": "address",
        "internalType": "contract IOptionalSystemHook"
      },
      {
        "name": "callDataHash",
        "type": "bytes32",
        "internalType": "bytes32"
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
    "name": "World_CustomUnregisterDelegationNotAllowed",
    "inputs": []
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
    "name": "World_OptionalHookAlreadyRegistered",
    "inputs": [
      {
        "name": "systemId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "hookAddress",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "callDataHash",
        "type": "bytes32",
        "internalType": "bytes32"
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
]; export default abi;
