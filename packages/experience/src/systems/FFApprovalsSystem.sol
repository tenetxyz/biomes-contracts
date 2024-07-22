// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ForceFieldApprovals, ForceFieldApprovalsData } from "../codegen/tables/ForceFieldApprovals.sol";
import { requireChipOwner, requireChipOwnerOrNoOwner } from "../Utils.sol";

contract FFApprovalsSystem is System {
  function setForceFieldApprovals(bytes32 entityId, ForceFieldApprovalsData memory approvals) public {
    requireChipOwner(entityId);
    ForceFieldApprovals.set(entityId, approvals);
  }

  function deleteForceFieldApprovals(bytes32 entityId) public {
    requireChipOwnerOrNoOwner(entityId);
    ForceFieldApprovals.deleteRecord(entityId);
  }

  function setFFApprovedPlayers(bytes32 entityId, address[] memory players) public {
    requireChipOwner(entityId);
    ForceFieldApprovals.setPlayers(entityId, players);
  }

  function pushFFApprovedPlayer(bytes32 entityId, address player) public {
    requireChipOwner(entityId);
    ForceFieldApprovals.pushPlayers(entityId, player);
  }

  function popFFApprovedPlayer(bytes32 entityId) public {
    requireChipOwner(entityId);
    ForceFieldApprovals.popPlayers(entityId);
  }

  function updateFFApprovedPlayer(bytes32 entityId, uint256 index, address player) public {
    requireChipOwner(entityId);
    ForceFieldApprovals.updatePlayers(entityId, index, player);
  }

  function setFFApprovedNFT(bytes32 entityId, address[] memory nfts) public {
    requireChipOwner(entityId);
    ForceFieldApprovals.setNfts(entityId, nfts);
  }

  function pushFFApprovedNFT(bytes32 entityId, address nft) public {
    requireChipOwner(entityId);
    ForceFieldApprovals.pushNfts(entityId, nft);
  }

  function popFFApprovedNFT(bytes32 entityId) public {
    requireChipOwner(entityId);
    ForceFieldApprovals.popNfts(entityId);
  }

  function updateFFApprovedNFT(bytes32 entityId, uint256 index, address nft) public {
    requireChipOwner(entityId);
    ForceFieldApprovals.updateNfts(entityId, index, nft);
  }
}
