// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

enum Biome {
  Mountains,
  Desert,
  Forest,
  Savanna
}

struct InventoryTool {
  bytes32 entityId;
  uint24 numUsesLeft;
}

struct InventoryObject {
  uint8 objectTypeId;
  uint16 numObjects;
  InventoryTool[] tools;
}

struct EntityData {
  uint8 objectTypeId;
  bytes32 entityId;
  InventoryObject[] inventory;
}

struct PickupData {
  uint8 objectTypeId;
  uint16 numToPickup;
}
