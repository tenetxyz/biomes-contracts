// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { EntityId } from "@biomesaw/world/src/EntityId.sol";

import { PipeAccess } from "../codegen/tables/PipeAccess.sol";
import { PipeAccessList } from "../codegen/tables/PipeAccessList.sol";
import { requireProgramOwner, requireProgramOwnerOrNoOwner } from "../Utils.sol";
import { pipeAccessExists } from "../utils/PipeUtils.sol";

contract PipeSystem is System {
  function setPipeAccess(
    EntityId targetEntityId,
    EntityId callerEntityId,
    bool depositAllowed,
    bool withdrawAllowed
  ) public {
    requireProgramOwner(targetEntityId);
    if (!depositAllowed && !withdrawAllowed) {
      deletePipeAccess(targetEntityId, callerEntityId);
    } else {
      PipeAccess.set(targetEntityId, callerEntityId, depositAllowed, withdrawAllowed);
      if (!pipeAccessExists(targetEntityId, callerEntityId)) {
        PipeAccessList.push(targetEntityId, EntityId.unwrap(callerEntityId));
      }
    }
  }

  function deletePipeAccess(EntityId targetEntityId, EntityId callerEntityId) public {
    requireProgramOwner(targetEntityId);
    require(pipeAccessExists(targetEntityId, callerEntityId), "Pipe access does not exist");
    bytes32[] memory approvedEntityIds = PipeAccessList.get(targetEntityId);
    bytes32[] memory newApprovedEntityIds = new bytes32[](approvedEntityIds.length - 1);
    uint256 newIndex = 0;
    for (uint256 i = 0; i < approvedEntityIds.length; i++) {
      if (EntityId.wrap(approvedEntityIds[i]) != callerEntityId) {
        newApprovedEntityIds[newIndex] = approvedEntityIds[i];
        newIndex++;
      }
    }
    PipeAccess.deleteRecord(targetEntityId, callerEntityId);
    PipeAccessList.set(targetEntityId, newApprovedEntityIds);
  }

  function deletePipeAccessList(EntityId targetEntityId) public {
    requireProgramOwnerOrNoOwner(targetEntityId);
    bytes32[] memory approvedEntityIds = PipeAccessList.get(targetEntityId);
    for (uint256 i = 0; i < approvedEntityIds.length; i++) {
      PipeAccess.deleteRecord(targetEntityId, EntityId.wrap(approvedEntityIds[i]));
    }
    PipeAccessList.deleteRecord(targetEntityId);
  }
}
