// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { PipeApproval } from "../codegen/tables/PipeApproval.sol";
import { PipeApprovals } from "../codegen/tables/PipeApprovals.sol";
import { requireChipOwner, requireChipOwnerOrNoOwner } from "../Utils.sol";

contract PipeApprovalsSystem is System {
  function pipeApprovalExists(bytes32 targetEntityId, bytes32 callerEntityId) internal view returns (bool) {
    bytes32[] memory approvedEntityIds = PipeApprovals.get(targetEntityId);
    for (uint256 i = 0; i < approvedEntityIds.length; i++) {
      if (approvedEntityIds[i] == callerEntityId) {
        return true;
      }
    }
    return false;
  }

  function setPipeApproval(bytes32 targetEntityId, bytes32 callerEntityId, bool approval) public {
    requireChipOwner(targetEntityId);
    require(!pipeApprovalExists(targetEntityId, callerEntityId), "Pipe approval already exists");
    PipeApproval.set(targetEntityId, callerEntityId, approval);
    PipeApprovals.push(targetEntityId, callerEntityId);
  }

  function deletePipeApproval(bytes32 targetEntityId, bytes32 callerEntityId) public {
    requireChipOwner(targetEntityId);
    require(pipeApprovalExists(targetEntityId, callerEntityId), "Pipe approval does not exist");
    bytes32[] memory approvedEntityIds = PipeApprovals.get(targetEntityId);
    bytes32[] memory newApprovedEntityIds = new bytes32[](approvedEntityIds.length - 1);
    uint256 newIndex = 0;
    for (uint256 i = 0; i < approvedEntityIds.length; i++) {
      if (approvedEntityIds[i] != callerEntityId) {
        newApprovedEntityIds[newIndex] = approvedEntityIds[i];
        newIndex++;
      }
    }
    PipeApproval.deleteRecord(targetEntityId, callerEntityId);
    PipeApprovals.set(targetEntityId, newApprovedEntityIds);
  }

  function deletePipeApprovals(bytes32 targetEntityId) public {
    requireChipOwnerOrNoOwner(targetEntityId);
    bytes32[] memory approvedEntityIds = PipeApprovals.get(targetEntityId);
    for (uint256 i = 0; i < approvedEntityIds.length; i++) {
      PipeApproval.deleteRecord(targetEntityId, approvedEntityIds[i]);
    }
    PipeApprovals.deleteRecord(targetEntityId);
  }
}
