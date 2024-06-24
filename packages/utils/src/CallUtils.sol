// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { SystemCall } from "@latticexyz/world/src/SystemCall.sol";
import { SystemRegistry } from "@latticexyz/world/src/codegen/tables/SystemRegistry.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { FunctionSelectors } from "@latticexyz/world/src/codegen/tables/FunctionSelectors.sol";
import { WorldContextProviderLib, WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";
import { ResourceId, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { revertWithBytes } from "@latticexyz/world/src/revertWithBytes.sol";
import { Bytes } from "@latticexyz/store/src/Bytes.sol";

function getCallerNamespace(address caller) view returns (bytes14) {
  ResourceId callerSystemId = SystemRegistry._get(caller);
  require(ResourceId.unwrap(callerSystemId) != bytes32(0), "Caller is not a system");
  return WorldResourceIdInstance.getNamespace(callerSystemId);
}

function callInternalSystem(bytes memory callData) returns (bytes memory) {
  (ResourceId systemId, bytes4 systemFunctionSelector) = FunctionSelectors._get(bytes4(callData));
  (address systemAddress, ) = Systems._get(systemId);

  (bool success, bytes memory returnData) = WorldContextProviderLib.delegatecallWithContext({
    msgSender: WorldContextConsumerLib._msgSender(),
    msgValue: 0,
    target: systemAddress,
    callData: Bytes.setBytes4(callData, 0, systemFunctionSelector)
  });

  if (!success) revertWithBytes(returnData);

  return returnData;
}

function staticCallInternalSystem(bytes memory callData) view returns (bytes memory) {
  (ResourceId systemId, bytes4 systemFunctionSelector) = FunctionSelectors._get(bytes4(callData));
  (address systemAddress, ) = Systems._get(systemId);

  (bool success, bytes memory returnData) = systemAddress.staticcall(
    WorldContextProviderLib.appendContext({
      callData: Bytes.setBytes4(callData, 0, systemFunctionSelector),
      msgSender: WorldContextConsumerLib._msgSender(),
      msgValue: 0
    })
  );

  if (!success) revertWithBytes(returnData);

  return returnData;
}
