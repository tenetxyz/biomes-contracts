// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Direction } from "../codegen/common.sol";
import { EnergyData } from "../codegen/tables/Energy.sol";

import { MovablePosition } from "../utils/Vec3Storage.sol";

import { EntityId } from "../EntityId.sol";
import { Vec3 } from "../Vec3.sol";

import { MoveNotifData, notify } from "../utils/NotifUtils.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";
import { MoveLib } from "./libraries/MoveLib.sol";

contract MoveSystem is System {
  function move(EntityId caller, Vec3[] memory newCoords) public {
    caller.activate();

    MoveLib.move(caller, MovablePosition._get(caller), newCoords);

    notify(caller, MoveNotifData({ moveCoords: newCoords }));
  }

  function moveDirections(EntityId caller, Direction[] memory directions) public {
    caller.activate();

    Vec3 coord = MovablePosition._get(caller);

    Vec3[] memory newCoords = new Vec3[](directions.length);
    for (uint256 i = 0; i < directions.length; i++) {
      newCoords[i] = (i == 0 ? coord : newCoords[i - 1]).transform(directions[i]);
    }

    MoveLib.move(caller, coord, newCoords);

    notify(caller, MoveNotifData({ moveCoords: newCoords }));
  }
}
