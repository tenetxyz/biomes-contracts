// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { Vec3 } from "../Vec3.sol";

import { EnergyData } from "../codegen/tables/Energy.sol";

import { MoveLib } from "./libraries/MoveLib.sol";
import { EntityId } from "../EntityId.sol";
import { Vec3 } from "../Vec3.sol";
import { requireValidPlayer } from "../utils/PlayerUtils.sol";
import { notify, MoveNotifData } from "../utils/NotifUtils.sol";

contract MoveSystem is System {
  function move(Vec3[] memory newCoords) public {
    (EntityId playerEntityId, Vec3 playerCoord, ) = requireValidPlayer(_msgSender());

    MoveLib.movePlayerWithGravity(playerEntityId, playerCoord, newCoords);

    notify(playerEntityId, MoveNotifData({ moveCoords: newCoords }));
  }

  function moveDirections(VoxelCoordDirection[] memory directions) public {
    (EntityId playerEntityId, Vec3 playerCoord, ) = requireValidPlayer(_msgSender());

    Vec3[] memory newCoords = new Vec3[](directions.length);
    for (uint256 i = 0; i < directions.length; i++) {
      newCoords[i] = (i == 0 ? playerCoord : newCoords[i - 1]).transform(directions[i]);
    }

    MoveLib.movePlayerWithGravity(playerEntityId, playerCoord, newCoords);

    notify(playerEntityId, MoveNotifData({ moveCoords: newCoords }));
  }
}
