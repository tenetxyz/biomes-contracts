// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { WorldContextConsumerLib, WorldContextProviderLib } from "@latticexyz/world/src/WorldContext.sol";
import { revertWithBytes } from "@latticexyz/world/src/revertWithBytes.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { EntityProgram } from "../codegen/tables/EntityProgram.sol";
import { EntityId } from "../EntityId.sol";
import { SAFE_PROGRAM_GAS } from "../Constants.sol";

function callProgram(ResourceId programSystemId, bytes memory callData) returns (bool, bytes memory) {
  address msgSender = WorldContextConsumerLib._msgSender();
  uint256 msgValue = WorldContextConsumerLib._msgValue();

  // If no program set, allow the call
  (address programAddress, ) = Systems._get(programSystemId);
  if (programAddress == address(0)) {
    return (true, "");
  }

  // If program is set, call it and return the result
  return
    programAddress.call{ value: 0 }(
      WorldContextProviderLib.appendContext({ callData: callData, msgSender: msgSender, msgValue: msgValue })
    );
}

function safeCallProgram(ResourceId programSystemId, bytes memory callData) returns (bool, bytes memory) {
  address msgSender = WorldContextConsumerLib._msgSender();
  uint256 msgValue = WorldContextConsumerLib._msgValue();

  (address programAddress, ) = Systems._get(programSystemId);
  if (programAddress == address(0)) {
    return (true, "");
  }

  return
    programAddress.call{ value: 0, gas: SAFE_PROGRAM_GAS }(
      WorldContextProviderLib.appendContext({ callData: callData, msgSender: msgSender, msgValue: msgValue })
    );
}

function callProgramOrRevert(ResourceId programSystemId, bytes memory callData) returns (bytes memory) {
  (bool success, bytes memory returnData) = callProgram(programSystemId, callData);
  if (!success) {
    revertWithBytes(returnData);
  }

  return returnData;
}
