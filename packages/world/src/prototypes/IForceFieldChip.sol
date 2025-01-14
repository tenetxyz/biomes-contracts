// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { IChip } from "./IChip.sol";

// Interface for a force field chip
interface IForceFieldChip is IChip {
  function onBuild(
    bytes32 targetEntityId,
    bytes32 callerEntityId,
    uint8 objectTypeId,
    VoxelCoord memory coord,
    bytes memory extraData
  ) external payable returns (bool isAllowed);

  function onMine(
    bytes32 targetEntityId,
    bytes32 callerEntityId,
    uint8 objectTypeId,
    VoxelCoord memory coord,
    bytes memory extraData
  ) external payable returns (bool isAllowed);

  // TODO: decide if we want force fields to control hits or not
  // function onHit(
  //   bytes32 targetEntityId,
  //   bytes32 callerEntityId,
  //   address hitPlayer,
  //   bytes memory extraData
  // ) external payable returns (bool isAllowed);
}
