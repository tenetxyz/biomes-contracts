// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ExperiencePoints } from "../codegen/tables/ExperiencePoints.sol";

function mintXP(bytes32 playerEntityId, uint256 initialGas) {
  uint256 gasUsed = initialGas - gasleft();
  uint256 txFeeGwei = (gasUsed * block.basefee) / 1e9;
  uint256 xpToMint = txFeeGwei / 750;
  uint256 currentXP = ExperiencePoints._get(playerEntityId);
  ExperiencePoints._set(playerEntityId, currentXP + xpToMint);
}

function burnXP(bytes32 playerEntityId, uint256 xpToBurn) returns (uint256) {
  uint256 currentXP = ExperiencePoints._get(playerEntityId);
  require(currentXP >= xpToBurn, "Player does not have enough xp");
  uint256 newXP = currentXP - xpToBurn;
  ExperiencePoints._set(playerEntityId, newXP);
  return newXP;
}
