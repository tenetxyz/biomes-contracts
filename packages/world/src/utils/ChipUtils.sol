// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Chip, ChipData } from "../codegen/tables/Chip.sol";

function updateChipBatteryLevel(bytes32 entityId) returns (ChipData memory) {
  ChipData memory chipData = Chip._get(entityId);

  if (chipData.batteryLevel > 0) {
    uint256 timeDiff = block.timestamp - chipData.lastUpdatedTime;
    uint256 batteryDecay = timeDiff / 60; // 1 minute
    if (batteryDecay > chipData.batteryLevel) {
      chipData.batteryLevel = 0;
      Chip._setBatteryLevel(entityId, 0);
    } else {
      chipData.batteryLevel -= batteryDecay;
      Chip._setBatteryLevel(entityId, chipData.batteryLevel - batteryDecay);
    }
    chipData.lastUpdatedTime = block.timestamp;
    Chip._setLastUpdatedTime(entityId, block.timestamp);
  }

  return chipData;
}
