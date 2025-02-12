// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord, VoxelCoordDirection } from "../Types.sol";
import { transformVoxelCoord } from "../utils/VoxelCoordUtils.sol";

import { requireValidPlayer } from "../utils/PlayerUtils.sol";
import { MoveLib } from "./libraries/MoveLib.sol";

import { EntityId } from "../EntityId.sol";

contract MoveSystem is System {
  function move(VoxelCoord[] memory newCoords) public {
    (EntityId playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());

    MoveLib.movePlayer(playerEntityId, playerCoord, newCoords);
  }

  function moveDirections(VoxelCoordDirection[] memory directions) public {
    (EntityId playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());

    VoxelCoord[] memory newCoords = new VoxelCoord[](directions.length);
    for (uint256 i = 0; i < directions.length; i++) {
      newCoords[i] = transformVoxelCoord(i == 0 ? playerCoord : newCoords[i - 1], directions[i]);
    }

    MoveLib.movePlayer(playerEntityId, playerCoord, newCoords);
  }
}
