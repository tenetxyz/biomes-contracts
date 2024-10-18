// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ExperiencePoints } from "../codegen/tables/ExperiencePoints.sol";

function mintXP(bytes32 playerEntityId, uint256 initialGas, uint256 multiplier) {
  uint256 gasUsed = initialGas - gasleft();
  uint256 txFeeWei = gasUsed * block.basefee;
  uint256 xpToMint = txFeeWei / (4200000 * multiplier);
  if (xpToMint == 0) {
    xpToMint = 1;
  }
  uint256 currentXP = ExperiencePoints._get(playerEntityId);
  ExperiencePoints._set(playerEntityId, currentXP + xpToMint);
}
