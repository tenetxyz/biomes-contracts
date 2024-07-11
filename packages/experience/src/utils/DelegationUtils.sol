// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";
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

function getBuildCallData(uint8 objectTypeId, VoxelCoord memory coord) pure returns (bytes memory buildCallData) {
  buildCallData = abi.encodeCall(IBuildSystem.build, (objectTypeId, coord, new bytes(0)));
  return buildCallData;
}

function callBuild(address delegatorAddress, uint8 objectTypeId, VoxelCoord memory coord) returns (bytes32 entityId) {
  bytes memory returnData = IWorld(WorldContextConsumerLib._world()).callFrom(
    delegatorAddress,
    getSystemId("BuildSystem"),
    getBuildCallData(objectTypeId, coord)
  );
  return abi.decode(returnData, (bytes32));
}

function getMineCallData(VoxelCoord memory coord) pure returns (bytes memory mineCallData) {
  mineCallData = abi.encodeCall(IMineSystem.mine, (coord, new bytes(0)));
  return mineCallData;
}

function callMine(address delegatorAddress, VoxelCoord memory coord) {
  IWorld(WorldContextConsumerLib._world()).callFrom(
    delegatorAddress,
    getSystemId("MineSystem"),
    getMineCallData(coord)
  );
}

function getMoveCallData(VoxelCoord[] memory newCoords) pure returns (bytes memory moveCallData) {
  moveCallData = abi.encodeCall(IMoveSystem.move, (newCoords));
  return moveCallData;
}

function callMove(address delegatorAddress, VoxelCoord[] memory newCoords) {
  IWorld(WorldContextConsumerLib._world()).callFrom(
    delegatorAddress,
    getSystemId("MoveSystem"),
    getMoveCallData(newCoords)
  );
}

function getHitCallData(address hitPlayer) pure returns (bytes memory hitCallData) {
  hitCallData = abi.encodeCall(IHitSystem.hit, (hitPlayer));
  return hitCallData;
}

function callHit(address delegatorAddress, address hitPlayer) {
  IWorld(WorldContextConsumerLib._world()).callFrom(
    delegatorAddress,
    getSystemId("HitSystem"),
    getHitCallData(hitPlayer)
  );
}

function getDropCallData(
  uint8 dropObjectTypeId,
  uint16 numToDrop,
  VoxelCoord memory coord,
  bytes32 toolEntityId
) pure returns (bytes memory dropCallData) {
  if (toolEntityId == bytes32(0)) {
    dropCallData = abi.encodeCall(IDropSystem.drop, (dropObjectTypeId, numToDrop, coord));
  } else {
    dropCallData = abi.encodeCall(IDropSystem.dropTool, (toolEntityId, coord));
  }
  return dropCallData;
}

function callDrop(
  address delegatorAddress,
  uint8 dropObjectTypeId,
  uint16 numToDrop,
  VoxelCoord memory coord,
  bytes32 toolEntityId
) {
  IWorld(WorldContextConsumerLib._world()).callFrom(
    delegatorAddress,
    getSystemId("DropSystem"),
    getDropCallData(dropObjectTypeId, numToDrop, coord, toolEntityId)
  );
}

function getTransferCallData(
  bytes32 srcEntityId,
  bytes32 dstEntityId,
  uint8 transferObjectTypeId,
  uint16 numToTransfer,
  bytes32 toolEntityId
) pure returns (bytes memory transferCallData) {
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
  return transferCallData;
}

function callTransfer(
  address delegatorAddress,
  bytes32 srcEntityId,
  bytes32 dstEntityId,
  uint8 transferObjectTypeId,
  uint16 numToTransfer,
  bytes32 toolEntityId
) {
  IWorld(WorldContextConsumerLib._world()).callFrom(
    delegatorAddress,
    getSystemId("TransferSystem"),
    getTransferCallData(srcEntityId, dstEntityId, transferObjectTypeId, numToTransfer, toolEntityId)
  );
}

function getCraftCallData(bytes32 recipeId, bytes32 stationEntityId) pure returns (bytes memory craftCallData) {
  craftCallData = abi.encodeCall(ICraftSystem.craft, (recipeId, stationEntityId));
  return craftCallData;
}

function callCraft(address delegatorAddress, bytes32 recipeId, bytes32 stationEntityId) {
  IWorld(WorldContextConsumerLib._world()).callFrom(
    delegatorAddress,
    getSystemId("CraftSystem"),
    getCraftCallData(recipeId, stationEntityId)
  );
}

function getEquipCallData(bytes32 entityId) pure returns (bytes memory equipCallData) {
  equipCallData = abi.encodeCall(IEquipSystem.equip, (entityId));
  return equipCallData;
}

function callEquip(address delegatorAddress, bytes32 entityId) {
  IWorld(WorldContextConsumerLib._world()).callFrom(
    delegatorAddress,
    getSystemId("EquipSystem"),
    getEquipCallData(entityId)
  );
}

function getUnequipCallData() pure returns (bytes memory unequipCallData) {
  unequipCallData = abi.encodeCall(IUnequipSystem.unequip, ());
  return unequipCallData;
}

function callUnequip(address delegatorAddress) {
  IWorld(WorldContextConsumerLib._world()).callFrom(
    delegatorAddress,
    getSystemId("UnequipSystem"),
    getUnequipCallData()
  );
}

function getLoginCallData(VoxelCoord memory respawnCoord) pure returns (bytes memory loginCallData) {
  loginCallData = abi.encodeCall(ILoginSystem.loginPlayer, (respawnCoord));
  return loginCallData;
}

function callLogin(address delegatorAddress, VoxelCoord memory respawnCoord) {
  IWorld(WorldContextConsumerLib._world()).callFrom(
    delegatorAddress,
    getSystemId("LoginSystem"),
    getLoginCallData(respawnCoord)
  );
}

function getLogoutCallData() pure returns (bytes memory logoutCallData) {
  logoutCallData = abi.encodeCall(ILogoffSystem.logoffPlayer, ());
  return logoutCallData;
}

function callLogout(address delegatorAddress) {
  IWorld(WorldContextConsumerLib._world()).callFrom(delegatorAddress, getSystemId("LogoffSystem"), getLogoutCallData());
}

function getSpawnCallData(VoxelCoord memory spawnCoord) pure returns (bytes memory spawnCallData) {
  spawnCallData = abi.encodeCall(ISpawnSystem.spawnPlayer, (spawnCoord));
  return spawnCallData;
}

function callSpawn(address delegatorAddress, VoxelCoord memory spawnCoord) {
  IWorld(WorldContextConsumerLib._world()).callFrom(
    delegatorAddress,
    getSystemId("SpawnSystem"),
    getSpawnCallData(spawnCoord)
  );
}

function getActivateCallData(bytes32 entityId) pure returns (bytes memory activateCallData) {
  activateCallData = abi.encodeCall(IActivateSystem.activate, (entityId));
  return activateCallData;
}

function callActivate(address delegatorAddress, bytes32 entityId) {
  IWorld(WorldContextConsumerLib._world()).callFrom(
    delegatorAddress,
    getSystemId("ActivateSystem"),
    getActivateCallData(entityId)
  );
}
