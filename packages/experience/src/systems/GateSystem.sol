// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { GateApprovals, GateApprovalsData } from "../codegen/tables/GateApprovals.sol";
import { requireChipOwner, requireChipOwnerOrNoOwner } from "../Utils.sol";

contract GateSystem is System {
  function setGateApprovals(bytes32 entityId, GateApprovalsData memory approvals) public {
    requireChipOwner(entityId);
    GateApprovals.set(entityId, approvals);
  }

  function deleteGateApprovals(bytes32 entityId) public {
    requireChipOwnerOrNoOwner(entityId);
    GateApprovals.deleteRecord(entityId);
  }

  function setGateApprovedPlayers(bytes32 entityId, address[] memory players) public {
    requireChipOwner(entityId);
    GateApprovals.setPlayers(entityId, players);
  }

  function pushGateApprovedPlayer(bytes32 entityId, address player) public {
    requireChipOwner(entityId);
    GateApprovals.pushPlayers(entityId, player);
  }

  function popGateApprovedPlayer(bytes32 entityId) public {
    requireChipOwner(entityId);
    GateApprovals.popPlayers(entityId);
  }

  function updateGateApprovedPlayer(bytes32 entityId, uint256 index, address player) public {
    requireChipOwner(entityId);
    GateApprovals.updatePlayers(entityId, index, player);
  }

  function setGateApprovedNFT(bytes32 entityId, address[] memory nfts) public {
    requireChipOwner(entityId);
    GateApprovals.setNfts(entityId, nfts);
  }

  function pushGateApprovedNFT(bytes32 entityId, address nft) public {
    requireChipOwner(entityId);
    GateApprovals.pushNfts(entityId, nft);
  }

  function popGateApprovedNFT(bytes32 entityId) public {
    requireChipOwner(entityId);
    GateApprovals.popNfts(entityId);
  }

  function updateGateApprovedNFT(bytes32 entityId, uint256 index, address nft) public {
    requireChipOwner(entityId);
    GateApprovals.updateNfts(entityId, index, nft);
  }
}
