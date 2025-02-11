// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "../Types.sol";
import { IChip } from "./IChip.sol";

// Interface for a force field chip
interface IForceFieldChip is IChip {
  function onBuild(
    bytes32 targetEntityId,
    bytes32 callerEntityId,
    uint16 objectTypeId,
    VoxelCoord memory coord,
    bytes memory extraData
  ) external payable returns (bool isAllowed);

  function onMine(
    bytes32 targetEntityId,
    bytes32 callerEntityId,
    uint16 objectTypeId,
    VoxelCoord memory coord,
    bytes memory extraData
  ) external payable returns (bool isAllowed);

  function onPowered(bytes32 callerEntityId, bytes32 targetEntityId, uint16 numBattery) external;

  function onForceFieldHit(bytes32 callerEntityId, bytes32 targetEntityId) external;
}
