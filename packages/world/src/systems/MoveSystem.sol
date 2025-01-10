// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord, VoxelCoordDirection } from "@biomesaw/utils/src/Types.sol";
import { transformVoxelCoord } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { callInternalSystem } from "@biomesaw/utils/src/CallUtils.sol";

import { requireValidPlayer } from "../utils/PlayerUtils.sol";
import { IMoveHelperSystem } from "../codegen/world/IMoveHelperSystem.sol";

contract MoveSystem is System {
  function move(VoxelCoord[] memory newCoords) public {
    uint256 initialGas = gasleft();

    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());

    callInternalSystem(
      abi.encodeCall(IMoveHelperSystem.movePlayer, (initialGas, playerEntityId, playerCoord, newCoords))
    );
  }

  function moveDirections(VoxelCoordDirection[] memory directions) public {
    uint256 initialGas = gasleft();

    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());

    VoxelCoord[] memory newCoords = new VoxelCoord[](directions.length);
    for (uint256 i = 0; i < directions.length; i++) {
      newCoords[i] = transformVoxelCoord(i == 0 ? playerCoord : newCoords[i - 1], directions[i]);
    }

    callInternalSystem(
      abi.encodeCall(IMoveHelperSystem.movePlayer, (initialGas, playerEntityId, playerCoord, newCoords))
    );
  }
}
