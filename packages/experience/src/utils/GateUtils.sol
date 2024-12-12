// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { GateApprovals } from "../codegen/tables/GateApprovals.sol";

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

function isApprovedPlayerForGate(bytes32 gateEntityId, address player) view returns (bool) {
  address[] memory approvedPlayers = GateApprovals.getPlayers(gateEntityId);
  for (uint256 i = 0; i < approvedPlayers.length; i++) {
    if (approvedPlayers[i] == player) {
      return true;
    }
  }

  return false;
}

function hasApprovedNftForGate(bytes32 gateEntityId, address player) view returns (bool) {
  address[] memory approvedNfts = GateApprovals.getNfts(gateEntityId);
  for (uint256 i = 0; i < approvedNfts.length; i++) {
    if (IERC721(approvedNfts[i]).balanceOf(player) > 0) {
      return true;
    }
  }

  return false;
}

function isApprovedForGate(bytes32 gateEntityId, address player) view returns (bool) {
  return isApprovedPlayerForGate(gateEntityId, player) || hasApprovedNftForGate(gateEntityId, player);
}
