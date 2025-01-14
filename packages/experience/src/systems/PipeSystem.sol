// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { PipeAccess } from "../codegen/tables/PipeAccess.sol";
import { PipeAccessList } from "../codegen/tables/PipeAccessList.sol";
import { PipeRouting } from "../codegen/tables/PipeRouting.sol";
import { PipeRoutingList } from "../codegen/tables/PipeRoutingList.sol";
import { requireChipOwner, requireChipOwnerOrNoOwner } from "../Utils.sol";

contract PipeSystem is System {
  function pipeAccessExists(bytes32 targetEntityId, bytes32 callerEntityId) internal view returns (bool) {
    bytes32[] memory approvedEntityIds = PipeAccessList.get(targetEntityId);
    for (uint256 i = 0; i < approvedEntityIds.length; i++) {
      if (approvedEntityIds[i] == callerEntityId) {
        return true;
      }
    }
    return false;
  }

  function pipeRoutingExists(bytes32 sourceEntityId, bytes32 targetEntityId) internal view returns (bool) {
    bytes32[] memory enabledEntityIds = PipeRoutingList.get(sourceEntityId);
    for (uint256 i = 0; i < enabledEntityIds.length; i++) {
      if (enabledEntityIds[i] == targetEntityId) {
        return true;
      }
    }
    return false;
  }

  function setPipeAccess(
    bytes32 targetEntityId,
    bytes32 callerEntityId,
    bool depositAllowed,
    bool withdrawAllowed
  ) public {
    requireChipOwner(targetEntityId);
    PipeAccess.set(targetEntityId, callerEntityId, depositAllowed, withdrawAllowed);
    if (!pipeAccessExists(targetEntityId, callerEntityId)) {
      PipeAccessList.push(targetEntityId, callerEntityId);
    }
  }

  function setPipeRouting(bytes32 sourceEntityId, bytes32 targetEntityId, bool enabled) public {
    requireChipOwner(sourceEntityId);
    PipeRouting.set(sourceEntityId, targetEntityId, enabled);
    if (!pipeRoutingExists(sourceEntityId, targetEntityId)) {
      PipeRoutingList.push(sourceEntityId, targetEntityId);
    }
  }

  function deletePipeAccess(bytes32 targetEntityId, bytes32 callerEntityId) public {
    requireChipOwner(targetEntityId);
    require(pipeAccessExists(targetEntityId, callerEntityId), "Pipe access does not exist");
    bytes32[] memory approvedEntityIds = PipeAccessList.get(targetEntityId);
    bytes32[] memory newApprovedEntityIds = new bytes32[](approvedEntityIds.length - 1);
    uint256 newIndex = 0;
    for (uint256 i = 0; i < approvedEntityIds.length; i++) {
      if (approvedEntityIds[i] != callerEntityId) {
        newApprovedEntityIds[newIndex] = approvedEntityIds[i];
        newIndex++;
      }
    }
    PipeAccess.deleteRecord(targetEntityId, callerEntityId);
    PipeAccessList.set(targetEntityId, newApprovedEntityIds);
  }

  function deletePipeRouting(bytes32 sourceEntityId, bytes32 targetEntityId) public {
    requireChipOwner(sourceEntityId);
    require(pipeRoutingExists(sourceEntityId, targetEntityId), "Pipe routing does not exist");
    bytes32[] memory enabledEntityIds = PipeRoutingList.get(sourceEntityId);
    bytes32[] memory newEnabledEntityIds = new bytes32[](enabledEntityIds.length - 1);
    uint256 newIndex = 0;
    for (uint256 i = 0; i < enabledEntityIds.length; i++) {
      if (enabledEntityIds[i] != targetEntityId) {
        newEnabledEntityIds[newIndex] = enabledEntityIds[i];
        newIndex++;
      }
    }
    PipeRouting.deleteRecord(sourceEntityId, targetEntityId);
    PipeRoutingList.set(sourceEntityId, newEnabledEntityIds);
  }

  function deletePipeAccessList(bytes32 targetEntityId) public {
    requireChipOwnerOrNoOwner(targetEntityId);
    bytes32[] memory approvedEntityIds = PipeAccessList.get(targetEntityId);
    for (uint256 i = 0; i < approvedEntityIds.length; i++) {
      PipeAccess.deleteRecord(targetEntityId, approvedEntityIds[i]);
    }
    PipeAccessList.deleteRecord(targetEntityId);
  }

  function deletePipeRoutingList(bytes32 sourceEntityId) public {
    requireChipOwnerOrNoOwner(sourceEntityId);
    bytes32[] memory enabledEntityIds = PipeRoutingList.get(sourceEntityId);
    for (uint256 i = 0; i < enabledEntityIds.length; i++) {
      PipeRouting.deleteRecord(sourceEntityId, enabledEntityIds[i]);
    }
    PipeRoutingList.deleteRecord(sourceEntityId);
  }
}
