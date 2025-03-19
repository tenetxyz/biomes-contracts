// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { EntityId } from "@biomesaw/world/src/EntityId.sol";

import { GateApprovals, GateApprovalsData } from "../codegen/tables/GateApprovals.sol";
import { requireProgramOwner, requireProgramOwnerOrNoOwner } from "../Utils.sol";

contract GateSystem is System {
  function setGateApprovals(EntityId entityId, GateApprovalsData memory approvals) public {
    requireProgramOwner(entityId);
    GateApprovals.set(entityId, approvals);
  }

  function deleteGateApprovals(EntityId entityId) public {
    requireProgramOwnerOrNoOwner(entityId);
    GateApprovals.deleteRecord(entityId);
  }

  function setGateApprovedPlayers(EntityId entityId, address[] memory players) public {
    requireProgramOwner(entityId);
    GateApprovals.setPlayers(entityId, players);
  }

  function pushGateApprovedPlayer(EntityId entityId, address player) public {
    requireProgramOwner(entityId);
    GateApprovals.pushPlayers(entityId, player);
  }

  function popGateApprovedPlayer(EntityId entityId) public {
    requireProgramOwner(entityId);
    GateApprovals.popPlayers(entityId);
  }

  function updateGateApprovedPlayer(EntityId entityId, uint256 index, address player) public {
    requireProgramOwner(entityId);
    GateApprovals.updatePlayers(entityId, index, player);
  }

  function setGateApprovedNFT(EntityId entityId, address[] memory nfts) public {
    requireProgramOwner(entityId);
    GateApprovals.setNfts(entityId, nfts);
  }

  function pushGateApprovedNFT(EntityId entityId, address nft) public {
    requireProgramOwner(entityId);
    GateApprovals.pushNfts(entityId, nft);
  }

  function popGateApprovedNFT(EntityId entityId) public {
    requireProgramOwner(entityId);
    GateApprovals.popNfts(entityId);
  }

  function updateGateApprovedNFT(EntityId entityId, uint256 index, address nft) public {
    requireProgramOwner(entityId);
    GateApprovals.updateNfts(entityId, index, nft);
  }
}
