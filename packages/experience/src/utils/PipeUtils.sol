// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { PipeAccess } from "../codegen/tables/PipeAccess.sol";
import { PipeAccessList } from "../codegen/tables/PipeAccessList.sol";
import { PipeRouting } from "../codegen/tables/PipeRouting.sol";
import { PipeRoutingList } from "../codegen/tables/PipeRoutingList.sol";

function pipeAccessExists(bytes32 targetEntityId, bytes32 callerEntityId) view returns (bool) {
  bytes32[] memory approvedEntityIds = PipeAccessList.get(targetEntityId);
  for (uint256 i = 0; i < approvedEntityIds.length; i++) {
    if (approvedEntityIds[i] == callerEntityId) {
      return true;
    }
  }
  return false;
}

function pipeRoutingExists(bytes32 sourceEntityId, bytes32 targetEntityId) view returns (bool) {
  bytes32[] memory enabledEntityIds = PipeRoutingList.get(sourceEntityId);
  for (uint256 i = 0; i < enabledEntityIds.length; i++) {
    if (enabledEntityIds[i] == targetEntityId) {
      return true;
    }
  }
  return false;
}
