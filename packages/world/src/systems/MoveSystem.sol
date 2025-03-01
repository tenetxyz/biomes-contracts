// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord, VoxelCoordDirection, VoxelCoordLib } from "../VoxelCoord.sol";
import { Vec3 } from "../Vec3.sol";

import { EnergyData } from "../codegen/tables/Energy.sol";

import { MoveLib } from "./libraries/MoveLib.sol";
import { EntityId } from "../EntityId.sol";
import { requireValidPlayer } from "../utils/PlayerUtils.sol";
import { notify, MoveNotifData } from "../utils/NotifUtils.sol";

contract MoveSystem is System {
  using VoxelCoordLib for *;

  function move(Vec3[] memory newCoords) public {
    (EntityId playerEntityId, VoxelCoord memory playerCoord, ) = requireValidPlayer(_msgSender());

    MoveLib.movePlayerWithGravity(playerEntityId, playerCoord, newCoords);

    notify(playerEntityId, MoveNotifData({ moveCoords: newCoords }));
  }

  function moveDirections(VoxelCoordDirection[] memory directions) public {
    (EntityId playerEntityId, VoxelCoord memory playerCoord, ) = requireValidPlayer(_msgSender());

    VoxelCoord[] memory newCoords = new VoxelCoord[](directions.length);
    for (uint256 i = 0; i < directions.length; i++) {
      newCoords[i] = (i == 0 ? playerCoord : newCoords[i - 1]).transform(directions[i]);
    }

    MoveLib.movePlayerWithGravity(playerEntityId, playerCoord, newCoords);

    notify(playerEntityId, MoveNotifData({ moveCoords: newCoords }));
  }
}
