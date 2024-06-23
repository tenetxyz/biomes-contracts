// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Chip, ChipData } from "../codegen/tables/Chip.sol";

import { TIME_BEFORE_DECREASE_BATTERY_LEVEL, BATTERY_DECREASE_RATE } from "../Constants.sol";

function updateChipBatteryLevel(bytes32 entityId) returns (ChipData memory) {
  ChipData memory chipData = Chip._get(entityId);

  if (chipData.batteryLevel > 0) {
    // Calculate how much time has passed since last update
    uint256 timeSinceLastUpdate = block.timestamp - chipData.lastUpdatedTime;
    if (timeSinceLastUpdate <= TIME_BEFORE_DECREASE_BATTERY_LEVEL) {
      return chipData;
    }

    uint256 decreaseBatteryLevel = (timeSinceLastUpdate / TIME_BEFORE_DECREASE_BATTERY_LEVEL) * BATTERY_DECREASE_RATE;
    uint256 newBatteryLevel = chipData.batteryLevel > decreaseBatteryLevel
      ? chipData.batteryLevel - decreaseBatteryLevel
      : 0;
    chipData.batteryLevel = newBatteryLevel;
    Chip._setBatteryLevel(entityId, newBatteryLevel);

    chipData.lastUpdatedTime = block.timestamp;
    Chip._setLastUpdatedTime(entityId, block.timestamp);
  }

  return chipData;
}
