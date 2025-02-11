// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { EntityId } from "@biomesaw/world/src/EntityId.sol";
import { PipeAccess } from "../codegen/tables/PipeAccess.sol";
import { PipeAccessList } from "../codegen/tables/PipeAccessList.sol";

function pipeAccessExists(EntityId targetEntityId, EntityId callerEntityId) view returns (bool) {
  bytes32[] memory approvedEntityIds = PipeAccessList.get(targetEntityId);
  for (uint256 i = 0; i < approvedEntityIds.length; i++) {
    if (EntityId.wrap(approvedEntityIds[i]) == callerEntityId) {
      return true;
    }
  }
  return false;
}
