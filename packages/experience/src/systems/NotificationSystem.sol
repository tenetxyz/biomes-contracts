// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { Notification } from "../codegen/tables/Notification.sol";

contract NotificationSystem is System {
  function setNotification(address player, string memory message) public {
    Notification.set(_msgSender(), player, message);
  }

  function deleteNotifications() public {
    Notification.deleteRecord(_msgSender());
  }
}
