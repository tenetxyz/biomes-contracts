// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { AirObjectID } from "@biomesaw/world/src/ObjectTypeIds.sol";

function weiToString(uint256 valueInWei) pure returns (string memory) {
  return string.concat(Strings.toString(valueInWei / 1 ether), ".", decimalString(valueInWei % 1 ether, 18));
}

function decimalString(uint256 value, uint256 decimals) pure returns (string memory) {
  if (value == 0) {
    return "0";
  }

  bytes memory buffer = new bytes(decimals);
  uint256 length = 0;
  for (uint256 i = 0; i < decimals; i++) {
    value *= 10;
    uint8 digit = uint8(value / 1 ether);
    buffer[i] = bytes1(48 + digit);
    value %= 1 ether;
    if (digit != 0) {
      length = i + 1;
    }
  }

  bytes memory trimmedBuffer = new bytes(length);
  for (uint256 i = 0; i < length; i++) {
    trimmedBuffer[i] = buffer[i];
  }

  return string(trimmedBuffer);
}
