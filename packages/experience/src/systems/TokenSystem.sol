// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { Tokens } from "../codegen/tables/Tokens.sol";

contract TokenSystem is System {
  function setTokens(address[] memory tokens) public {
    Tokens.setTokens(_msgSender(), tokens);
  }

  function pushTokens(address token) public {
    Tokens.pushTokens(_msgSender(), token);
  }

  function popTokens() public {
    Tokens.popTokens(_msgSender());
  }

  function updateTokens(uint256 index, address token) public {
    Tokens.updateTokens(_msgSender(), index, token);
  }

  function deleteTokens() public {
    Tokens.deleteRecord(_msgSender());
  }
}
