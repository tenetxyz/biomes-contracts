// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ExperiencePoints } from "../../codegen/tables/ExperiencePoints.sol";
import { getL1GasPrice } from "../../Utils.sol";

contract MintXPSystem is System {
  function mintXP(bytes32 playerEntityId, uint256 initialGas, uint256 multiplier) public payable {
    uint256 l1GasPriceWei = getL1GasPrice();
    // Ensure that the gas price is at least 8 gwei
    if (l1GasPriceWei < 8 gwei) {
      l1GasPriceWei = 8 gwei;
    }
    uint256 gasUsed = initialGas - gasleft();
    uint256 txFeeWei = gasUsed * block.basefee * l1GasPriceWei;
    uint256 xpToMint = txFeeWei / (4200000 * 8 gwei * multiplier);
    if (xpToMint == 0) {
      xpToMint = 1;
    }
    uint256 currentXP = ExperiencePoints._get(playerEntityId);
    ExperiencePoints._set(playerEntityId, currentXP + xpToMint);
  }
}
