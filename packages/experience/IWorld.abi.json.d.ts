declare const abi: [
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
    "name": "experience__addExchange",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "exchangeId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "exchangeInfoData",
        "type": "tuple",
        "internalType": "struct ExchangeInfoData",
        "components": [
          {
            "name": "inResourceType",
            "type": "uint8",
            "internalType": "enum ResourceType"
          },
          {
            "name": "inResourceId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "inUnitAmount",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "inMaxAmount",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "outResourceType",
            "type": "uint8",
            "internalType": "enum ResourceType"
          },
          {
            "name": "outResourceId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "outUnitAmount",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "outMaxAmount",
            "type": "uint256",
            "internalType": "uint256"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__deleteArea",
    "inputs": [
      {
        "name": "areaId",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__deleteAsset",
    "inputs": [
      {
        "name": "asset",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__deleteBuild",
    "inputs": [
      {
        "name": "buildId",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__deleteBuildWithPos",
    "inputs": [
      {
        "name": "buildId",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__deleteChestMetadata",
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
    "name": "experience__deleteChipAdmin",
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
    "name": "experience__deleteChipAttacher",
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
    "name": "experience__deleteChipMetadata",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__deleteChipNamespace",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__deleteCountdown",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__deleteExchange",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "exchangeId",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__deleteExchangeNotif",
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
    "name": "experience__deleteExchanges",
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
    "name": "experience__deleteExperienceMetadata",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__deleteForceFieldApprovals",
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
    "name": "experience__deleteForceFieldMetadata",
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
    "name": "experience__deleteGateApprovals",
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
    "name": "experience__deleteNFTMetadata",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__deleteNamespaceId",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__deleteNfts",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__deleteNotifications",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__deletePlayers",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__deleteRegisterMsg",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__deleteShop",
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
    "name": "experience__deleteShopNotif",
    "inputs": [
      {
        "name": "chestEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__deleteSmartItemMetadata",
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
    "name": "experience__deleteStatus",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__deleteTokenMetadata",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__deleteTokens",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__deleteUnregisterMsg",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__emitExchangeNotif",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "notifData",
        "type": "tuple",
        "internalType": "struct ExchangeNotifData",
        "components": [
          {
            "name": "player",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "inResourceType",
            "type": "uint8",
            "internalType": "enum ResourceType"
          },
          {
            "name": "inResourceId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "inAmount",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "outResourceType",
            "type": "uint8",
            "internalType": "enum ResourceType"
          },
          {
            "name": "outResourceId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "outAmount",
            "type": "uint256",
            "internalType": "uint256"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__emitShopNotif",
    "inputs": [
      {
        "name": "chestEntityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "notifData",
        "type": "tuple",
        "internalType": "struct ItemShopNotifData",
        "components": [
          {
            "name": "player",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "shopTxType",
            "type": "uint8",
            "internalType": "enum ShopTxType"
          },
          {
            "name": "objectTypeId",
            "type": "uint8",
            "internalType": "uint8"
          },
          {
            "name": "amount",
            "type": "uint16",
            "internalType": "uint16"
          },
          {
            "name": "price",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "paymentToken",
            "type": "address",
            "internalType": "address"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__getBlockEntityData",
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
        "internalType": "struct BlockExperienceEntityData",
        "components": [
          {
            "name": "worldEntityData",
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
          },
          {
            "name": "chipAttacher",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "chestMetadata",
            "type": "tuple",
            "internalType": "struct ChestMetadataData",
            "components": [
              {
                "name": "name",
                "type": "string",
                "internalType": "string"
              },
              {
                "name": "description",
                "type": "string",
                "internalType": "string"
              }
            ]
          },
          {
            "name": "itemShopData",
            "type": "tuple",
            "internalType": "struct ItemShopData",
            "components": [
              {
                "name": "shopType",
                "type": "uint8",
                "internalType": "enum ShopType"
              },
              {
                "name": "objectTypeId",
                "type": "uint8",
                "internalType": "uint8"
              },
              {
                "name": "buyPrice",
                "type": "uint256",
                "internalType": "uint256"
              },
              {
                "name": "sellPrice",
                "type": "uint256",
                "internalType": "uint256"
              },
              {
                "name": "paymentToken",
                "type": "address",
                "internalType": "address"
              },
              {
                "name": "balance",
                "type": "uint256",
                "internalType": "uint256"
              }
            ]
          },
          {
            "name": "ffMetadata",
            "type": "tuple",
            "internalType": "struct FFMetadataData",
            "components": [
              {
                "name": "name",
                "type": "string",
                "internalType": "string"
              },
              {
                "name": "description",
                "type": "string",
                "internalType": "string"
              }
            ]
          },
          {
            "name": "forceFieldApprovalsData",
            "type": "tuple",
            "internalType": "struct ForceFieldApprovalsData",
            "components": [
              {
                "name": "players",
                "type": "address[]",
                "internalType": "address[]"
              },
              {
                "name": "nfts",
                "type": "address[]",
                "internalType": "address[]"
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
    "name": "experience__getBlockEntityDataWithExchanges",
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
        "internalType": "struct BlockExperienceEntityDataWithExchanges",
        "components": [
          {
            "name": "worldEntityData",
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
          },
          {
            "name": "chipAttacher",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "chipAdmin",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "smartItemMetadata",
            "type": "tuple",
            "internalType": "struct SmartItemMetadataData",
            "components": [
              {
                "name": "name",
                "type": "string",
                "internalType": "string"
              },
              {
                "name": "description",
                "type": "string",
                "internalType": "string"
              }
            ]
          },
          {
            "name": "gateApprovalsData",
            "type": "tuple",
            "internalType": "struct GateApprovalsData",
            "components": [
              {
                "name": "players",
                "type": "address[]",
                "internalType": "address[]"
              },
              {
                "name": "nfts",
                "type": "address[]",
                "internalType": "address[]"
              }
            ]
          },
          {
            "name": "exchanges",
            "type": "tuple[]",
            "internalType": "struct ExchangeInfoDataWithExchangeId[]",
            "components": [
              {
                "name": "exchangeId",
                "type": "bytes32",
                "internalType": "bytes32"
              },
              {
                "name": "exchangeInfoData",
                "type": "tuple",
                "internalType": "struct ExchangeInfoData",
                "components": [
                  {
                    "name": "inResourceType",
                    "type": "uint8",
                    "internalType": "enum ResourceType"
                  },
                  {
                    "name": "inResourceId",
                    "type": "bytes32",
                    "internalType": "bytes32"
                  },
                  {
                    "name": "inUnitAmount",
                    "type": "uint256",
                    "internalType": "uint256"
                  },
                  {
                    "name": "inMaxAmount",
                    "type": "uint256",
                    "internalType": "uint256"
                  },
                  {
                    "name": "outResourceType",
                    "type": "uint8",
                    "internalType": "enum ResourceType"
                  },
                  {
                    "name": "outResourceId",
                    "type": "bytes32",
                    "internalType": "bytes32"
                  },
                  {
                    "name": "outUnitAmount",
                    "type": "uint256",
                    "internalType": "uint256"
                  },
                  {
                    "name": "outMaxAmount",
                    "type": "uint256",
                    "internalType": "uint256"
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
    "name": "experience__getBlockEntityDataWithGateApprovals",
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
        "internalType": "struct BlockExperienceEntityDataWithGateApprovals",
        "components": [
          {
            "name": "worldEntityData",
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
          },
          {
            "name": "chipAttacher",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "chestMetadata",
            "type": "tuple",
            "internalType": "struct ChestMetadataData",
            "components": [
              {
                "name": "name",
                "type": "string",
                "internalType": "string"
              },
              {
                "name": "description",
                "type": "string",
                "internalType": "string"
              }
            ]
          },
          {
            "name": "itemShopData",
            "type": "tuple",
            "internalType": "struct ItemShopData",
            "components": [
              {
                "name": "shopType",
                "type": "uint8",
                "internalType": "enum ShopType"
              },
              {
                "name": "objectTypeId",
                "type": "uint8",
                "internalType": "uint8"
              },
              {
                "name": "buyPrice",
                "type": "uint256",
                "internalType": "uint256"
              },
              {
                "name": "sellPrice",
                "type": "uint256",
                "internalType": "uint256"
              },
              {
                "name": "paymentToken",
                "type": "address",
                "internalType": "address"
              },
              {
                "name": "balance",
                "type": "uint256",
                "internalType": "uint256"
              }
            ]
          },
          {
            "name": "ffMetadata",
            "type": "tuple",
            "internalType": "struct FFMetadataData",
            "components": [
              {
                "name": "name",
                "type": "string",
                "internalType": "string"
              },
              {
                "name": "description",
                "type": "string",
                "internalType": "string"
              }
            ]
          },
          {
            "name": "forceFieldApprovalsData",
            "type": "tuple",
            "internalType": "struct ForceFieldApprovalsData",
            "components": [
              {
                "name": "players",
                "type": "address[]",
                "internalType": "address[]"
              },
              {
                "name": "nfts",
                "type": "address[]",
                "internalType": "address[]"
              }
            ]
          },
          {
            "name": "gateApprovalsData",
            "type": "tuple",
            "internalType": "struct GateApprovalsData",
            "components": [
              {
                "name": "players",
                "type": "address[]",
                "internalType": "address[]"
              },
              {
                "name": "nfts",
                "type": "address[]",
                "internalType": "address[]"
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
    "name": "experience__getBlocksEntityData",
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
        "internalType": "struct BlockExperienceEntityData[]",
        "components": [
          {
            "name": "worldEntityData",
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
          },
          {
            "name": "chipAttacher",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "chestMetadata",
            "type": "tuple",
            "internalType": "struct ChestMetadataData",
            "components": [
              {
                "name": "name",
                "type": "string",
                "internalType": "string"
              },
              {
                "name": "description",
                "type": "string",
                "internalType": "string"
              }
            ]
          },
          {
            "name": "itemShopData",
            "type": "tuple",
            "internalType": "struct ItemShopData",
            "components": [
              {
                "name": "shopType",
                "type": "uint8",
                "internalType": "enum ShopType"
              },
              {
                "name": "objectTypeId",
                "type": "uint8",
                "internalType": "uint8"
              },
              {
                "name": "buyPrice",
                "type": "uint256",
                "internalType": "uint256"
              },
              {
                "name": "sellPrice",
                "type": "uint256",
                "internalType": "uint256"
              },
              {
                "name": "paymentToken",
                "type": "address",
                "internalType": "address"
              },
              {
                "name": "balance",
                "type": "uint256",
                "internalType": "uint256"
              }
            ]
          },
          {
            "name": "ffMetadata",
            "type": "tuple",
            "internalType": "struct FFMetadataData",
            "components": [
              {
                "name": "name",
                "type": "string",
                "internalType": "string"
              },
              {
                "name": "description",
                "type": "string",
                "internalType": "string"
              }
            ]
          },
          {
            "name": "forceFieldApprovalsData",
            "type": "tuple",
            "internalType": "struct ForceFieldApprovalsData",
            "components": [
              {
                "name": "players",
                "type": "address[]",
                "internalType": "address[]"
              },
              {
                "name": "nfts",
                "type": "address[]",
                "internalType": "address[]"
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
    "name": "experience__getBlocksEntityDataWithExchanges",
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
        "internalType": "struct BlockExperienceEntityDataWithExchanges[]",
        "components": [
          {
            "name": "worldEntityData",
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
          },
          {
            "name": "chipAttacher",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "chipAdmin",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "smartItemMetadata",
            "type": "tuple",
            "internalType": "struct SmartItemMetadataData",
            "components": [
              {
                "name": "name",
                "type": "string",
                "internalType": "string"
              },
              {
                "name": "description",
                "type": "string",
                "internalType": "string"
              }
            ]
          },
          {
            "name": "gateApprovalsData",
            "type": "tuple",
            "internalType": "struct GateApprovalsData",
            "components": [
              {
                "name": "players",
                "type": "address[]",
                "internalType": "address[]"
              },
              {
                "name": "nfts",
                "type": "address[]",
                "internalType": "address[]"
              }
            ]
          },
          {
            "name": "exchanges",
            "type": "tuple[]",
            "internalType": "struct ExchangeInfoDataWithExchangeId[]",
            "components": [
              {
                "name": "exchangeId",
                "type": "bytes32",
                "internalType": "bytes32"
              },
              {
                "name": "exchangeInfoData",
                "type": "tuple",
                "internalType": "struct ExchangeInfoData",
                "components": [
                  {
                    "name": "inResourceType",
                    "type": "uint8",
                    "internalType": "enum ResourceType"
                  },
                  {
                    "name": "inResourceId",
                    "type": "bytes32",
                    "internalType": "bytes32"
                  },
                  {
                    "name": "inUnitAmount",
                    "type": "uint256",
                    "internalType": "uint256"
                  },
                  {
                    "name": "inMaxAmount",
                    "type": "uint256",
                    "internalType": "uint256"
                  },
                  {
                    "name": "outResourceType",
                    "type": "uint8",
                    "internalType": "enum ResourceType"
                  },
                  {
                    "name": "outResourceId",
                    "type": "bytes32",
                    "internalType": "bytes32"
                  },
                  {
                    "name": "outUnitAmount",
                    "type": "uint256",
                    "internalType": "uint256"
                  },
                  {
                    "name": "outMaxAmount",
                    "type": "uint256",
                    "internalType": "uint256"
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
    "name": "experience__getBlocksEntityDataWithGateApprovals",
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
        "internalType": "struct BlockExperienceEntityDataWithGateApprovals[]",
        "components": [
          {
            "name": "worldEntityData",
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
          },
          {
            "name": "chipAttacher",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "chestMetadata",
            "type": "tuple",
            "internalType": "struct ChestMetadataData",
            "components": [
              {
                "name": "name",
                "type": "string",
                "internalType": "string"
              },
              {
                "name": "description",
                "type": "string",
                "internalType": "string"
              }
            ]
          },
          {
            "name": "itemShopData",
            "type": "tuple",
            "internalType": "struct ItemShopData",
            "components": [
              {
                "name": "shopType",
                "type": "uint8",
                "internalType": "enum ShopType"
              },
              {
                "name": "objectTypeId",
                "type": "uint8",
                "internalType": "uint8"
              },
              {
                "name": "buyPrice",
                "type": "uint256",
                "internalType": "uint256"
              },
              {
                "name": "sellPrice",
                "type": "uint256",
                "internalType": "uint256"
              },
              {
                "name": "paymentToken",
                "type": "address",
                "internalType": "address"
              },
              {
                "name": "balance",
                "type": "uint256",
                "internalType": "uint256"
              }
            ]
          },
          {
            "name": "ffMetadata",
            "type": "tuple",
            "internalType": "struct FFMetadataData",
            "components": [
              {
                "name": "name",
                "type": "string",
                "internalType": "string"
              },
              {
                "name": "description",
                "type": "string",
                "internalType": "string"
              }
            ]
          },
          {
            "name": "forceFieldApprovalsData",
            "type": "tuple",
            "internalType": "struct ForceFieldApprovalsData",
            "components": [
              {
                "name": "players",
                "type": "address[]",
                "internalType": "address[]"
              },
              {
                "name": "nfts",
                "type": "address[]",
                "internalType": "address[]"
              }
            ]
          },
          {
            "name": "gateApprovalsData",
            "type": "tuple",
            "internalType": "struct GateApprovalsData",
            "components": [
              {
                "name": "players",
                "type": "address[]",
                "internalType": "address[]"
              },
              {
                "name": "nfts",
                "type": "address[]",
                "internalType": "address[]"
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
    "name": "experience__popFFApprovedNFT",
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
    "name": "experience__popFFApprovedPlayer",
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
    "name": "experience__popGateApprovedNFT",
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
    "name": "experience__popGateApprovedPlayer",
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
    "name": "experience__popNfts",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__popPlayers",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__popTokens",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__pushFFApprovedNFT",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "nft",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__pushFFApprovedPlayer",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
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
    "name": "experience__pushGateApprovedNFT",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "nft",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__pushGateApprovedPlayer",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
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
    "name": "experience__pushNfts",
    "inputs": [
      {
        "name": "nft",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__pushPlayers",
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
    "name": "experience__pushTokens",
    "inputs": [
      {
        "name": "token",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setArea",
    "inputs": [
      {
        "name": "areaId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "name",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "area",
        "type": "tuple",
        "internalType": "struct Area",
        "components": [
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
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setAsset",
    "inputs": [
      {
        "name": "asset",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "assetType",
        "type": "uint8",
        "internalType": "enum ResourceType"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setBuild",
    "inputs": [
      {
        "name": "buildId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "name",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "build",
        "type": "tuple",
        "internalType": "struct Build",
        "components": [
          {
            "name": "objectTypeIds",
            "type": "uint8[]",
            "internalType": "uint8[]"
          },
          {
            "name": "relativePositions",
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
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setBuildWithPos",
    "inputs": [
      {
        "name": "buildId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "name",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "build",
        "type": "tuple",
        "internalType": "struct BuildWithPos",
        "components": [
          {
            "name": "objectTypeIds",
            "type": "uint8[]",
            "internalType": "uint8[]"
          },
          {
            "name": "relativePositions",
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
            "name": "baseWorldCoord",
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
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setBuyPrice",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "buyPrice",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setBuyShop",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "buyObjectTypeId",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "buyPrice",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "paymentToken",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setChestDescription",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "description",
        "type": "string",
        "internalType": "string"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setChestMetadata",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "metadata",
        "type": "tuple",
        "internalType": "struct ChestMetadataData",
        "components": [
          {
            "name": "name",
            "type": "string",
            "internalType": "string"
          },
          {
            "name": "description",
            "type": "string",
            "internalType": "string"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setChestName",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "name",
        "type": "string",
        "internalType": "string"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setChipAdmin",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "admin",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setChipAttacher",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "attacher",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setChipMetadata",
    "inputs": [
      {
        "name": "metadata",
        "type": "tuple",
        "internalType": "struct ChipMetadataData",
        "components": [
          {
            "name": "chipType",
            "type": "uint8",
            "internalType": "enum ChipType"
          },
          {
            "name": "name",
            "type": "string",
            "internalType": "string"
          },
          {
            "name": "description",
            "type": "string",
            "internalType": "string"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setChipNamespace",
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
    "name": "experience__setCountdown",
    "inputs": [
      {
        "name": "countdownData",
        "type": "tuple",
        "internalType": "struct CountdownData",
        "components": [
          {
            "name": "countdownEndTimestamp",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "countdownEndBlock",
            "type": "uint256",
            "internalType": "uint256"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setCountdownEndBlock",
    "inputs": [
      {
        "name": "countdownEndBlock",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setCountdownEndTimestamp",
    "inputs": [
      {
        "name": "countdownEndTimestamp",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setExchangeInMaxAmount",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "exchangeId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "inMaxAmount",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setExchangeInUnitAmount",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "exchangeId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "inUnitAmount",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setExchangeOutMaxAmount",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "exchangeId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "outMaxAmount",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setExchangeOutUnitAmount",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "exchangeId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "outUnitAmount",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setExchanges",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "exchangeIds",
        "type": "bytes32[]",
        "internalType": "bytes32[]"
      },
      {
        "name": "exchangeInfoData",
        "type": "tuple[]",
        "internalType": "struct ExchangeInfoData[]",
        "components": [
          {
            "name": "inResourceType",
            "type": "uint8",
            "internalType": "enum ResourceType"
          },
          {
            "name": "inResourceId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "inUnitAmount",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "inMaxAmount",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "outResourceType",
            "type": "uint8",
            "internalType": "enum ResourceType"
          },
          {
            "name": "outResourceId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "outUnitAmount",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "outMaxAmount",
            "type": "uint256",
            "internalType": "uint256"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setExperienceMetadata",
    "inputs": [
      {
        "name": "metadata",
        "type": "tuple",
        "internalType": "struct ExperienceMetadataData",
        "components": [
          {
            "name": "shouldDelegate",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "joinFee",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "hookSystemIds",
            "type": "bytes32[]",
            "internalType": "bytes32[]"
          },
          {
            "name": "name",
            "type": "string",
            "internalType": "string"
          },
          {
            "name": "description",
            "type": "string",
            "internalType": "string"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setFFApprovedNFT",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "nfts",
        "type": "address[]",
        "internalType": "address[]"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setFFApprovedPlayers",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "players",
        "type": "address[]",
        "internalType": "address[]"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setForceFieldApprovals",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "approvals",
        "type": "tuple",
        "internalType": "struct ForceFieldApprovalsData",
        "components": [
          {
            "name": "players",
            "type": "address[]",
            "internalType": "address[]"
          },
          {
            "name": "nfts",
            "type": "address[]",
            "internalType": "address[]"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setForceFieldDescription",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "description",
        "type": "string",
        "internalType": "string"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setForceFieldMetadata",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "metadata",
        "type": "tuple",
        "internalType": "struct FFMetadataData",
        "components": [
          {
            "name": "name",
            "type": "string",
            "internalType": "string"
          },
          {
            "name": "description",
            "type": "string",
            "internalType": "string"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setForceFieldName",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "name",
        "type": "string",
        "internalType": "string"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setGateApprovals",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "approvals",
        "type": "tuple",
        "internalType": "struct GateApprovalsData",
        "components": [
          {
            "name": "players",
            "type": "address[]",
            "internalType": "address[]"
          },
          {
            "name": "nfts",
            "type": "address[]",
            "internalType": "address[]"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setGateApprovedNFT",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "nfts",
        "type": "address[]",
        "internalType": "address[]"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setGateApprovedPlayers",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "players",
        "type": "address[]",
        "internalType": "address[]"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setJoinFee",
    "inputs": [
      {
        "name": "joinFee",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setMUDNFTMetadata",
    "inputs": [
      {
        "name": "namespaceId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "metadata",
        "type": "tuple",
        "internalType": "struct ERC721MetadataData",
        "components": [
          {
            "name": "systemId",
            "type": "bytes32",
            "internalType": "ResourceId"
          },
          {
            "name": "creator",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "symbol",
            "type": "string",
            "internalType": "string"
          },
          {
            "name": "name",
            "type": "string",
            "internalType": "string"
          },
          {
            "name": "description",
            "type": "string",
            "internalType": "string"
          },
          {
            "name": "baseURI",
            "type": "string",
            "internalType": "string"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setMUDTokenMetadata",
    "inputs": [
      {
        "name": "namespaceId",
        "type": "bytes32",
        "internalType": "ResourceId"
      },
      {
        "name": "metadata",
        "type": "tuple",
        "internalType": "struct ERC20MetadataData",
        "components": [
          {
            "name": "systemId",
            "type": "bytes32",
            "internalType": "ResourceId"
          },
          {
            "name": "creator",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "decimals",
            "type": "uint8",
            "internalType": "uint8"
          },
          {
            "name": "symbol",
            "type": "string",
            "internalType": "string"
          },
          {
            "name": "name",
            "type": "string",
            "internalType": "string"
          },
          {
            "name": "description",
            "type": "string",
            "internalType": "string"
          },
          {
            "name": "icon",
            "type": "string",
            "internalType": "string"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setNFTMetadata",
    "inputs": [
      {
        "name": "metadata",
        "type": "tuple",
        "internalType": "struct ERC721MetadataData",
        "components": [
          {
            "name": "systemId",
            "type": "bytes32",
            "internalType": "ResourceId"
          },
          {
            "name": "creator",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "symbol",
            "type": "string",
            "internalType": "string"
          },
          {
            "name": "name",
            "type": "string",
            "internalType": "string"
          },
          {
            "name": "description",
            "type": "string",
            "internalType": "string"
          },
          {
            "name": "baseURI",
            "type": "string",
            "internalType": "string"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setNamespaceId",
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
    "name": "experience__setNfts",
    "inputs": [
      {
        "name": "nfts",
        "type": "address[]",
        "internalType": "address[]"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setNotification",
    "inputs": [
      {
        "name": "player",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "message",
        "type": "string",
        "internalType": "string"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setPlayers",
    "inputs": [
      {
        "name": "players",
        "type": "address[]",
        "internalType": "address[]"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setRegisterMsg",
    "inputs": [
      {
        "name": "registerMessage",
        "type": "string",
        "internalType": "string"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setSellPrice",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "sellPrice",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setSellShop",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "sellObjectTypeId",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "sellPrice",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "paymentToken",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setShop",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "shopData",
        "type": "tuple",
        "internalType": "struct ItemShopData",
        "components": [
          {
            "name": "shopType",
            "type": "uint8",
            "internalType": "enum ShopType"
          },
          {
            "name": "objectTypeId",
            "type": "uint8",
            "internalType": "uint8"
          },
          {
            "name": "buyPrice",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "sellPrice",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "paymentToken",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "balance",
            "type": "uint256",
            "internalType": "uint256"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setShopBalance",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "balance",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setShopObjectTypeId",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
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
    "name": "experience__setSmartItemDescription",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "description",
        "type": "string",
        "internalType": "string"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setSmartItemMetadata",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "metadata",
        "type": "tuple",
        "internalType": "struct SmartItemMetadataData",
        "components": [
          {
            "name": "name",
            "type": "string",
            "internalType": "string"
          },
          {
            "name": "description",
            "type": "string",
            "internalType": "string"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setSmartItemName",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "name",
        "type": "string",
        "internalType": "string"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setStatus",
    "inputs": [
      {
        "name": "status",
        "type": "string",
        "internalType": "string"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setTokenMetadata",
    "inputs": [
      {
        "name": "metadata",
        "type": "tuple",
        "internalType": "struct ERC20MetadataData",
        "components": [
          {
            "name": "systemId",
            "type": "bytes32",
            "internalType": "ResourceId"
          },
          {
            "name": "creator",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "decimals",
            "type": "uint8",
            "internalType": "uint8"
          },
          {
            "name": "symbol",
            "type": "string",
            "internalType": "string"
          },
          {
            "name": "name",
            "type": "string",
            "internalType": "string"
          },
          {
            "name": "description",
            "type": "string",
            "internalType": "string"
          },
          {
            "name": "icon",
            "type": "string",
            "internalType": "string"
          }
        ]
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setTokens",
    "inputs": [
      {
        "name": "tokens",
        "type": "address[]",
        "internalType": "address[]"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__setUnregisterMsg",
    "inputs": [
      {
        "name": "unregisterMessage",
        "type": "string",
        "internalType": "string"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__updateFFApprovedNFT",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "index",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "nft",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__updateFFApprovedPlayer",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "index",
        "type": "uint256",
        "internalType": "uint256"
      },
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
    "name": "experience__updateGateApprovedNFT",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "index",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "nft",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__updateGateApprovedPlayer",
    "inputs": [
      {
        "name": "entityId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "index",
        "type": "uint256",
        "internalType": "uint256"
      },
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
    "name": "experience__updateNfts",
    "inputs": [
      {
        "name": "index",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "nft",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "experience__updatePlayers",
    "inputs": [
      {
        "name": "index",
        "type": "uint256",
        "internalType": "uint256"
      },
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
    "name": "experience__updateTokens",
    "inputs": [
      {
        "name": "index",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "token",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
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
