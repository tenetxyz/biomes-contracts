// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Slice, SliceLib } from "@latticexyz/store/src/Slice.sol";

import { IBuildSystem } from "@biomesaw/world/src/codegen/world/IBuildSystem.sol";
import { ICraftSystem } from "@biomesaw/world/src/codegen/world/ICraftSystem.sol";
import { IDropSystem } from "@biomesaw/world/src/codegen/world/IDropSystem.sol";
import { IEquipSystem } from "@biomesaw/world/src/codegen/world/IEquipSystem.sol";
import { IHitSystem } from "@biomesaw/world/src/codegen/world/IHitSystem.sol";
import { ILoginSystem } from "@biomesaw/world/src/codegen/world/ILoginSystem.sol";
import { ILogoffSystem } from "@biomesaw/world/src/codegen/world/ILogoffSystem.sol";
import { IMineSystem } from "@biomesaw/world/src/codegen/world/IMineSystem.sol";
import { IMoveSystem } from "@biomesaw/world/src/codegen/world/IMoveSystem.sol";
import { ISpawnSystem } from "@biomesaw/world/src/codegen/world/ISpawnSystem.sol";
import { ITransferSystem } from "@biomesaw/world/src/codegen/world/ITransferSystem.sol";
import { IUnequipSystem } from "@biomesaw/world/src/codegen/world/IUnequipSystem.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { getObjectType } from "./EntityUtils.sol";

function decodeCallData(bytes memory callData) pure returns (bytes4, bytes memory) {
  Slice selectorSlice = SliceLib.getSubslice(callData, 0, 4);
  Slice callDataArgs = SliceLib.getSubslice(callData, 4);
  return (bytes4(selectorSlice.toBytes()), callDataArgs.toBytes());
}

function getBuildArgs(bytes memory callData) pure returns (uint8 objectTypeId, VoxelCoord memory coord) {
  (bytes4 selector, bytes memory args) = decodeCallData(callData);
  require(selector == IBuildSystem.build.selector, "Invalid selector");
  return abi.decode(args, (uint8, VoxelCoord));
}

function getMineArgs(bytes memory callData) pure returns (VoxelCoord memory coord) {
  (bytes4 selector, bytes memory args) = decodeCallData(callData);
  require(selector == IMineSystem.mine.selector, "Invalid selector");
  return abi.decode(args, (VoxelCoord));
}

function getMoveArgs(bytes memory callData) pure returns (VoxelCoord[] memory newCoords) {
  (bytes4 selector, bytes memory args) = decodeCallData(callData);
  require(selector == IMoveSystem.move.selector, "Invalid selector");
  return abi.decode(args, (VoxelCoord[]));
}

function getHitArgs(bytes memory callData) pure returns (address hitPlayer) {
  (bytes4 selector, bytes memory args) = decodeCallData(callData);
  require(selector == IHitSystem.hit.selector, "Invalid selector");
  return abi.decode(args, (address));
}

function getDropArgs(
  bytes memory callData
) view returns (uint8 dropObjectTypeId, uint16 numToDrop, VoxelCoord memory coord, bytes32 toolEntityId) {
  (bytes4 selector, bytes memory args) = decodeCallData(callData);
  if (selector == IDropSystem.drop.selector) {
    (dropObjectTypeId, numToDrop, coord) = abi.decode(args, (uint8, uint16, VoxelCoord));
  } else if (selector == IDropSystem.dropTool.selector) {
    (toolEntityId, coord) = abi.decode(args, (bytes32, VoxelCoord));
    numToDrop = 1;
    dropObjectTypeId = getObjectType(toolEntityId);
  } else {
    revert("Invalid selector");
  }
  return (dropObjectTypeId, numToDrop, coord, toolEntityId);
}

function getTransferArgs(
  bytes memory callData
)
  view
  returns (
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    uint8 transferObjectTypeId,
    uint16 numToTransfer,
    bytes32 toolEntityId
  )
{
  (bytes4 selector, bytes memory args) = decodeCallData(callData);
  if (selector == ITransferSystem.transfer.selector) {
    (srcEntityId, dstEntityId, transferObjectTypeId, numToTransfer) = abi.decode(
      args,
      (bytes32, bytes32, uint8, uint16)
    );
  } else if (selector == ITransferSystem.transferTool.selector) {
    (srcEntityId, dstEntityId, toolEntityId) = abi.decode(args, (bytes32, bytes32, bytes32));
    numToTransfer = 1;
    transferObjectTypeId = getObjectType(toolEntityId);
  } else {
    revert("Invalid selector");
  }
  return (srcEntityId, dstEntityId, transferObjectTypeId, numToTransfer, toolEntityId);
}

function getCraftArgs(bytes memory callData) pure returns (bytes32 recipeId, bytes32 stationEntityId) {
  (bytes4 selector, bytes memory args) = decodeCallData(callData);
  require(selector == ICraftSystem.craft.selector, "Invalid selector");
  return abi.decode(args, (bytes32, bytes32));
}

function getEquipArgs(bytes memory callData) pure returns (bytes32 inventoryEntityId) {
  (bytes4 selector, bytes memory args) = decodeCallData(callData);
  require(selector == IEquipSystem.equip.selector, "Invalid selector");
  return abi.decode(args, (bytes32));
}

function getLoginArgs(bytes memory callData) pure returns (VoxelCoord memory respawnCoord) {
  (bytes4 selector, bytes memory args) = decodeCallData(callData);
  require(selector == ILoginSystem.loginPlayer.selector, "Invalid selector");
  return abi.decode(args, (VoxelCoord));
}

function getSpawnArgs(bytes memory callData) pure returns (VoxelCoord memory spawnCoord) {
  (bytes4 selector, bytes memory args) = decodeCallData(callData);
  require(selector == ISpawnSystem.spawnPlayer.selector, "Invalid selector");
  return abi.decode(args, (VoxelCoord));
}
