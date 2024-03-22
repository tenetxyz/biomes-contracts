// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ITerrainSystem } from "./codegen/world/ITerrainSystem.sol";
import { IGravitySystem } from "./codegen/world/IGravitySystem.sol";
import { SystemCall } from "@latticexyz/world/src/SystemCall.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { FunctionSelectors } from "@latticexyz/world/src/codegen/tables/FunctionSelectors.sol";
import { WorldContextProviderLib, WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { revertWithBytes } from "@latticexyz/world/src/revertWithBytes.sol";
import { Bytes } from "@latticexyz/store/src/Bytes.sol";

import { Position, PositionData } from "./codegen/tables/Position.sol";
import { LastKnownPosition, LastKnownPositionData } from "./codegen/tables/LastKnownPosition.sol";
import { ObjectTypeMetadata } from "./codegen/tables/ObjectTypeMetadata.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

function positionDataToVoxelCoord(PositionData memory coord) pure returns (VoxelCoord memory) {
  return VoxelCoord(coord.x, coord.y, coord.z);
}

function lastKnownPositionDataToVoxelCoord(LastKnownPositionData memory coord) pure returns (VoxelCoord memory) {
  return VoxelCoord(coord.x, coord.y, coord.z);
}

function getTerrainObjectTypeId(bytes32 objectTypeId, VoxelCoord memory coord) view returns (bytes32) {
  address terrainAddress = ObjectTypeMetadata.getOccurenceAddress(objectTypeId);
  bytes4 terrainSelector = ObjectTypeMetadata.getOccurenceSelector(objectTypeId);
  // require(terrainAddress != address(0) && terrainSelector != bytes4(0), "ObjectTypeMetadata: object type not found");
  (bool success, bytes memory returnData) = terrainAddress.staticcall(abi.encodeWithSelector(terrainSelector, coord));
  require(success, "getTerrainObjectTypeId: call failed");
  return abi.decode(returnData, (bytes32));
}

function callGravity(bytes32 playerEntityId, VoxelCoord memory coord) returns (bool) {
  bytes memory callData = abi.encodeCall(IGravitySystem.runGravity, (playerEntityId, coord));
  (ResourceId systemId, bytes4 systemFunctionSelector) = FunctionSelectors.get(bytes4(callData));
  (address systemAddress, ) = Systems._get(systemId);

  (bool success, bytes memory returnData) = WorldContextProviderLib.delegatecallWithContext({
    msgSender: WorldContextConsumerLib._msgSender(),
    msgValue: 0,
    target: systemAddress,
    callData: Bytes.setBytes4(callData, 0, systemFunctionSelector)
  });

  if (!success) revertWithBytes(returnData);

  return abi.decode(returnData, (bool));
}
