// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { Countdown, CountdownData } from "../codegen/tables/Countdown.sol";

import { getExperienceAddress } from "../Utils.sol";

contract CountdownSystem is System {
  function setCountdown(CountdownData memory countdownData) public {
    Countdown.set(getExperienceAddress(_msgSender()), countdownData);
  }

  function setCountdownEndTimestamp(uint256 countdownEndTimestamp) public {
    Countdown.setCountdownEndTimestamp(getExperienceAddress(_msgSender()), countdownEndTimestamp);
  }

  function setCountdownEndBlock(uint256 countdownEndBlock) public {
    Countdown.setCountdownEndBlock(getExperienceAddress(_msgSender()), countdownEndBlock);
  }

  function deleteCountdown() public {
    Countdown.deleteRecord(getExperienceAddress(_msgSender()));
  }
}
