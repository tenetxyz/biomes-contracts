// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Direction } from "../codegen/common.sol";
import { EnergyData } from "../codegen/tables/Energy.sol";

import { MovablePosition } from "../utils/Vec3Storage.sol";

import { MoveLib } from "./libraries/MoveLib.sol";
import { EntityId } from "../EntityId.sol";
import { Vec3 } from "../Vec3.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";
import { notify, MoveNotifData } from "../utils/NotifUtils.sol";

contract MoveSystem is System {
  function move(EntityId callerEntityId, Vec3[] memory newCoords) public {
    callerEntityId.activate();

    MoveLib.move(callerEntityId, MovablePosition._get(callerEntityId), newCoords);

    notify(callerEntityId, MoveNotifData({ moveCoords: newCoords }));
  }

  function moveDirections(EntityId callerEntityId, Direction[] memory directions) public {
    callerEntityId.activate();

    Vec3 coord = MovablePosition._get(callerEntityId);

    Vec3[] memory newCoords = new Vec3[](directions.length);
    for (uint256 i = 0; i < directions.length; i++) {
      newCoords[i] = (i == 0 ? coord : newCoords[i - 1]).transform(directions[i]);
    }

    MoveLib.move(callerEntityId, coord, newCoords);

    notify(callerEntityId, MoveNotifData({ moveCoords: newCoords }));
  }
}
