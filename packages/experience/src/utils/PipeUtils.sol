// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { PipeAccess } from "../codegen/tables/PipeAccess.sol";
import { PipeAccessList } from "../codegen/tables/PipeAccessList.sol";

function pipeAccessExists(bytes32 targetEntityId, bytes32 callerEntityId) view returns (bool) {
  bytes32[] memory approvedEntityIds = PipeAccessList.get(targetEntityId);
  for (uint256 i = 0; i < approvedEntityIds.length; i++) {
    if (approvedEntityIds[i] == callerEntityId) {
      return true;
    }
  }
  return false;
}
