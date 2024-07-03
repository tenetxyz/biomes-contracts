// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";

import { IWorld } from "@biomesaw/world/src/codegen/world/IWorld.sol";
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
import { IActivateSystem } from "@biomesaw/world/src/codegen/world/IActivateSystem.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { getObjectType } from "./EntityUtils.sol";

function getSystemId(bytes16 systemName) pure returns (ResourceId) {
  return WorldResourceIdLib.encode({ typeId: RESOURCE_SYSTEM, namespace: "", name: systemName });
}

function getNamespaceSystemId(bytes14 namespace, bytes16 systemName) pure returns (ResourceId) {
  return WorldResourceIdLib.encode({ typeId: RESOURCE_SYSTEM, namespace: namespace, name: systemName });
}

function isSystemId(ResourceId checkSystemId, bytes16 systemId) pure returns (bool) {
  return ResourceId.unwrap(checkSystemId) == ResourceId.unwrap(getSystemId(systemId));
}

function callBuild(
  address biomeWorldAddress,
  address delegatorAddress,
  uint8 objectTypeId,
  VoxelCoord memory coord
) returns (bytes32 entityId) {
  bytes memory buildCallData = abi.encodeCall(IBuildSystem.build, (objectTypeId, coord));
  bytes memory returnData = IWorld(biomeWorldAddress).callFrom(
    delegatorAddress,
    getSystemId("BuildSystem"),
    buildCallData
  );
  return abi.decode(returnData, (bytes32));
}

function callMine(address biomeWorldAddress, address delegatorAddress, VoxelCoord memory coord) {
  bytes memory mineCallData = abi.encodeCall(IMineSystem.mine, (coord));
  IWorld(biomeWorldAddress).callFrom(delegatorAddress, getSystemId("MineSystem"), mineCallData);
}

function callMove(address biomeWorldAddress, address delegatorAddress, VoxelCoord[] memory newCoords) {
  bytes memory moveCallData = abi.encodeCall(IMoveSystem.move, (newCoords));
  IWorld(biomeWorldAddress).callFrom(delegatorAddress, getSystemId("MoveSystem"), moveCallData);
}

function callHit(address biomeWorldAddress, address delegatorAddress, address hitPlayer) {
  bytes memory hitCallData = abi.encodeCall(IHitSystem.hit, (hitPlayer));
  IWorld(biomeWorldAddress).callFrom(delegatorAddress, getSystemId("HitSystem"), hitCallData);
}

function callDrop(
  address biomeWorldAddress,
  address delegatorAddress,
  uint8 dropObjectTypeId,
  uint16 numToDrop,
  VoxelCoord memory coord,
  bytes32 toolEntityId
) {
  bytes memory dropCallData;
  if (toolEntityId == bytes32(0)) {
    dropCallData = abi.encodeCall(IDropSystem.drop, (dropObjectTypeId, numToDrop, coord));
  } else {
    dropCallData = abi.encodeCall(IDropSystem.dropTool, (toolEntityId, coord));
  }
  IWorld(biomeWorldAddress).callFrom(delegatorAddress, getSystemId("DropSystem"), dropCallData);
}

function callTransfer(
  address biomeWorldAddress,
  address delegatorAddress,
  bytes32 srcEntityId,
  bytes32 dstEntityId,
  uint8 transferObjectTypeId,
  uint16 numToTransfer,
  bytes32 toolEntityId
) {
  bytes memory transferCallData;
  if (toolEntityId == bytes32(0)) {
    transferCallData = abi.encodeCall(
      ITransferSystem.transfer,
      (srcEntityId, dstEntityId, transferObjectTypeId, numToTransfer, new bytes(0))
    );
  } else {
    transferCallData = abi.encodeCall(
      ITransferSystem.transferTool,
      (srcEntityId, dstEntityId, toolEntityId, new bytes(0))
    );
  }
  IWorld(biomeWorldAddress).callFrom(delegatorAddress, getSystemId("TransferSystem"), transferCallData);
}

function callCraft(address biomeWorldAddress, address delegatorAddress, bytes32 recipeId, bytes32 stationEntityId) {
  bytes memory craftCallData = abi.encodeCall(ICraftSystem.craft, (recipeId, stationEntityId));
  IWorld(biomeWorldAddress).callFrom(delegatorAddress, getSystemId("CraftSystem"), craftCallData);
}

function callEquip(address biomeWorldAddress, address delegatorAddress, bytes32 entityId) {
  bytes memory equipCallData = abi.encodeCall(IEquipSystem.equip, (entityId));
  IWorld(biomeWorldAddress).callFrom(delegatorAddress, getSystemId("EquipSystem"), equipCallData);
}

function callUnequip(address biomeWorldAddress, address delegatorAddress) {
  bytes memory unequipCallData = abi.encodeCall(IUnequipSystem.unequip, ());
  IWorld(biomeWorldAddress).callFrom(delegatorAddress, getSystemId("UnequipSystem"), unequipCallData);
}

function callLogin(address biomeWorldAddress, address delegatorAddress, VoxelCoord memory respawnCoord) {
  bytes memory loginCallData = abi.encodeCall(ILoginSystem.loginPlayer, (respawnCoord));
  IWorld(biomeWorldAddress).callFrom(delegatorAddress, getSystemId("LoginSystem"), loginCallData);
}

function callLogout(address biomeWorldAddress, address delegatorAddress) {
  bytes memory logoutCallData = abi.encodeCall(ILogoffSystem.logoffPlayer, ());
  IWorld(biomeWorldAddress).callFrom(delegatorAddress, getSystemId("LogoffSystem"), logoutCallData);
}

function callSpawn(address biomeWorldAddress, address delegatorAddress, VoxelCoord memory spawnCoord) {
  bytes memory spawnCallData = abi.encodeCall(ISpawnSystem.spawnPlayer, (spawnCoord));
  IWorld(biomeWorldAddress).callFrom(delegatorAddress, getSystemId("SpawnSystem"), spawnCallData);
}

function callActivate(address biomeWorldAddress, address delegatorAddress, bytes32 entityId) {
  bytes memory activateCallData = abi.encodeCall(IActivateSystem.activate, (entityId));
  IWorld(biomeWorldAddress).callFrom(delegatorAddress, getSystemId("ActivateSystem"), activateCallData);
}
