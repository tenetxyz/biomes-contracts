// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Chip, ChipData } from "../codegen/tables/Chip.sol";

import { TIME_BEFORE_DECREASE_BATTERY_LEVEL } from "../Constants.sol";

function updateChipBatteryLevel(bytes32 entityId) returns (ChipData memory) {
  ChipData memory chipData = Chip._get(entityId);

  if (chipData.batteryLevel > 0) {
    // Calculate how much time has passed since last update
    uint256 timeSinceLastUpdate = block.timestamp - chipData.lastUpdatedTime;
    if (timeSinceLastUpdate <= TIME_BEFORE_DECREASE_BATTERY_LEVEL) {
      return chipData;
    }

    uint256 newBatteryLevel = chipData.batteryLevel > timeSinceLastUpdate
      ? chipData.batteryLevel - timeSinceLastUpdate
      : 0;
    chipData.batteryLevel = newBatteryLevel;
    Chip._setBatteryLevel(entityId, newBatteryLevel);

    chipData.lastUpdatedTime = block.timestamp;
    Chip._setLastUpdatedTime(entityId, block.timestamp);
  }

  return chipData;
}
