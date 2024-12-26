// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { DisplayStatus } from "../../codegen/tables/DisplayStatus.sol";
import { DisplayRegisterMsg } from "../../codegen/tables/DisplayRegisterMsg.sol";
import { DisplayUnregisterMsg } from "../../codegen/tables/DisplayUnregisterMsg.sol";

contract DisplaySystem is System {
  function setStatus(string memory status) public {
    DisplayStatus.set(_msgSender(), status);
  }

  function deleteStatus() public {
    DisplayStatus.deleteRecord(_msgSender());
  }

  function setRegisterMsg(string memory registerMessage) public {
    DisplayRegisterMsg.set(_msgSender(), registerMessage);
  }

  function deleteRegisterMsg() public {
    DisplayRegisterMsg.deleteRecord(_msgSender());
  }

  function setUnregisterMsg(string memory unregisterMessage) public {
    DisplayUnregisterMsg.set(_msgSender(), unregisterMessage);
  }

  function deleteUnregisterMsg() public {
    DisplayUnregisterMsg.deleteRecord(_msgSender());
  }
}
