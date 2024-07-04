// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { Players } from "../codegen/tables/Players.sol";

import { getExperienceAddress } from "../Utils.sol";

contract PlayerSystem is System {
  function setPlayers(address[] memory players) public {
    Players.setPlayers(getExperienceAddress(_msgSender()), players);
  }

  function pushPlayers(address player) public {
    Players.pushPlayers(getExperienceAddress(_msgSender()), player);
  }

  function popPlayers() public {
    Players.popPlayers(getExperienceAddress(_msgSender()));
  }

  function updatePlayers(uint256 index, address player) public {
    Players.updatePlayers(getExperienceAddress(_msgSender()), index, player);
  }

  function deletePlayers() public {
    Players.deleteRecord(getExperienceAddress(_msgSender()));
  }
}
