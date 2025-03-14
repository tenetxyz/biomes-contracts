// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { WorldContextConsumerLib, WorldContextProviderLib } from "@latticexyz/world/src/WorldContext.sol";
import { revertWithBytes } from "@latticexyz/world/src/revertWithBytes.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { Chip } from "../codegen/tables/Chip.sol";
import { EntityId } from "../EntityId.sol";
import { SAFE_CHIP_GAS } from "../Constants.sol";

function callChip(ResourceId chipSystemId, bytes memory callData) returns (bool, bytes memory) {
  address msgSender = WorldContextConsumerLib._msgSender();
  uint256 msgValue = WorldContextConsumerLib._msgValue();

  (address chipAddress, ) = Systems._get(chipSystemId);
  if (chipAddress == address(0)) {
    return (true, "");
  }

  return
    chipAddress.call{ value: 0 }(
      WorldContextProviderLib.appendContext({ callData: callData, msgSender: msgSender, msgValue: msgValue })
    );
}

function safeCallChip(ResourceId chipSystemId, bytes memory callData) returns (bool, bytes memory) {
  address msgSender = WorldContextConsumerLib._msgSender();
  uint256 msgValue = WorldContextConsumerLib._msgValue();

  (address chipAddress, ) = Systems._get(chipSystemId);
  if (chipAddress == address(0)) {
    return (true, "");
  }

  return
    chipAddress.call{ value: 0, gas: SAFE_CHIP_GAS }(
      WorldContextProviderLib.appendContext({ callData: callData, msgSender: msgSender, msgValue: msgValue })
    );
}

function callChipOrRevert(ResourceId chipSystemId, bytes memory callData) returns (bytes memory) {
  (bool success, bytes memory returnData) = callChip(chipSystemId, callData);
  if (!success) {
    revertWithBytes(returnData);
  }

  return returnData;
}
