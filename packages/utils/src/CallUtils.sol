// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

enum CallType {
  Call,
  StaticCall,
  DelegateCall
}

function safeGenericCall(
  CallType callType,
  address target,
  bytes memory callData,
  string memory functionName
) returns (bool, bytes memory) {
  bool success;
  bytes memory returnData;

  if (callType == CallType.Call) {
    (success, returnData) = target.call(callData);
  } else if (callType == CallType.StaticCall) {
    (success, returnData) = target.staticcall(callData);
  } else if (callType == CallType.DelegateCall) {
    (success, returnData) = target.delegatecall(callData);
  }

  return (success, returnData);
}

// bubbles up a revert reason string if the call fails
function genericCallOrRevert(
  CallType callType,
  address target,
  bytes memory callData,
  string memory functionName
) returns (bytes memory) {
  (bool success, bytes memory returnData) = safeGenericCall(callType, target, callData, functionName);

  if (!success) {
    // if there is a return reason string
    if (returnData.length > 0) {
      // bubble up any reason for revert
      assembly {
        let returnDataSize := mload(returnData)
        revert(add(32, returnData), returnDataSize)
      }
    } else {
      string memory revertMsg = string(
        abi.encodePacked(functionName, " call reverted. Maybe the params aren't right?")
      );
      revert(revertMsg);
    }
  }

  return returnData;
}

function callOrRevert(address target, bytes memory callData, string memory functionName) returns (bytes memory) {
  return genericCallOrRevert(CallType.Call, target, callData, functionName);
}

function safeCall(address target, bytes memory callData, string memory functionName) returns (bool, bytes memory) {
  return safeGenericCall(CallType.Call, target, callData, functionName);
}

function staticCallOrRevert(
  address target,
  bytes memory callData,
  string memory functionName
) view returns (bytes memory) {
  (bool success, bytes memory returnData) = safeStaticCall(target, callData, functionName);

  if (!success) {
    // if there is a return reason string
    if (returnData.length > 0) {
      // bubble up any reason for revert
      assembly {
        let returnDataSize := mload(returnData)
        revert(add(32, returnData), returnDataSize)
      }
    } else {
      string memory revertMsg = string(
        abi.encodePacked(functionName, " call reverted. Maybe the params aren't right?")
      );
      revert(revertMsg);
    }
  }

  return returnData;
}

function safeStaticCall(
  address target,
  bytes memory callData,
  string memory functionName
) view returns (bool, bytes memory) {
  (bool success, bytes memory returnData) = target.staticcall(callData);

  return (success, returnData);
}

function delegateCallOrRevert(
  address target,
  bytes memory callData,
  string memory functionName
) returns (bytes memory) {
  return genericCallOrRevert(CallType.DelegateCall, target, callData, functionName);
}
