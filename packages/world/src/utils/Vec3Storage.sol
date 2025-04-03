// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { EncodedLengths } from "@latticexyz/store/src/EncodedLengths.sol";
import { FieldLayout } from "@latticexyz/store/src/FieldLayout.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { StoreCore } from "@latticexyz/store/src/StoreCore.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";

import { ExploredChunk as _ExploredChunk } from "../codegen/tables/ExploredChunk.sol";

import {
  ForceFieldFragment as _ForceFieldFragment, ForceFieldFragmentData
} from "../codegen/tables/ForceFieldFragment.sol";
import { ForceFieldFragmentPosition as _ForceFieldFragmentPosition } from
  "../codegen/tables/ForceFieldFragmentPosition.sol";
import { InitialEnergyPool as _InitialEnergyPool } from "../codegen/tables/InitialEnergyPool.sol";
import { LocalEnergyPool as _LocalEnergyPool } from "../codegen/tables/LocalEnergyPool.sol";

import { ChunkCommitment as _ChunkCommitment } from "../codegen/tables/ChunkCommitment.sol";
import { MovablePosition as _MovablePosition } from "../codegen/tables/MovablePosition.sol";
import { Position as _Position } from "../codegen/tables/Position.sol";
import { ResourcePosition as _ResourcePosition } from "../codegen/tables/ResourcePosition.sol";
import { ReverseMovablePosition as _ReverseMovablePosition } from "../codegen/tables/ReverseMovablePosition.sol";
import { ReversePosition as _ReversePosition } from "../codegen/tables/ReversePosition.sol";

import { SurfaceChunkByIndex as _SurfaceChunkByIndex } from "../codegen/tables/SurfaceChunkByIndex.sol";

import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { Vec3 } from "../Vec3.sol";

/// @dev Library to get and set Vec3s in tables. It only support schemas of <single key> -> Vec3 and Vec3 -> <single value>
library Vec3Storage {
  function get(ResourceId tableId, FieldLayout fieldLayout, bytes32 key) internal view returns (Vec3 output) {
    (bytes memory _staticData,,) = StoreSwitch.getRecord(tableId, _encodeKeyTuple(key), fieldLayout);

    assembly {
      output := mload(add(_staticData, 0xc))
    }
  }

  function _get(ResourceId tableId, FieldLayout fieldLayout, bytes32 key) internal view returns (Vec3 output) {
    (bytes memory _staticData,,) = StoreCore.getRecord(tableId, _encodeKeyTuple(key), fieldLayout);

    assembly {
      output := mload(add(_staticData, 0xc))
    }
  }

  function getAsBytes(ResourceId tableId, FieldLayout fieldLayout, Vec3 position)
    internal
    view
    returns (bytes memory output)
  {
    (output,,) = StoreSwitch.getRecord(tableId, _encodeKeyTuple(position), fieldLayout);
  }

  function _getAsBytes(ResourceId tableId, FieldLayout fieldLayout, Vec3 position)
    internal
    view
    returns (bytes memory output)
  {
    (output,,) = StoreCore.getRecord(tableId, _encodeKeyTuple(position), fieldLayout);
  }

  function get(ResourceId tableId, FieldLayout fieldLayout, Vec3 vec) internal view returns (bytes32) {
    return StoreSwitch.getStaticField(tableId, _encodeKeyTuple(vec), 0, fieldLayout);
  }

  function _get(ResourceId tableId, FieldLayout fieldLayout, Vec3 vec) internal view returns (bytes32) {
    return StoreCore.getStaticField(tableId, _encodeKeyTuple(vec), 0, fieldLayout);
  }

  function getStatic(ResourceId tableId, FieldLayout fieldLayout, uint8 fieldIndex, Vec3 vec)
    internal
    view
    returns (bytes32)
  {
    return StoreSwitch.getStaticField(tableId, _encodeKeyTuple(vec), fieldIndex, fieldLayout);
  }

  function _getStatic(ResourceId tableId, FieldLayout fieldLayout, uint8 fieldIndex, Vec3 vec)
    internal
    view
    returns (bytes32)
  {
    return StoreCore.getStaticField(tableId, _encodeKeyTuple(vec), fieldIndex, fieldLayout);
  }

  function set(ResourceId tableId, bytes32 key, Vec3 vec) internal {
    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;
    StoreSwitch.setRecord(tableId, _encodeKeyTuple(key), abi.encodePacked(vec), _encodedLengths, _dynamicData);
  }

  function _set(ResourceId tableId, bytes32 key, Vec3 vec) internal {
    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;
    StoreCore.setRecord(tableId, _encodeKeyTuple(key), abi.encodePacked(vec), _encodedLengths, _dynamicData);
  }

  function set(ResourceId tableId, FieldLayout fieldLayout, Vec3 vec, bytes memory packedValue) internal {
    StoreSwitch.setStaticField(tableId, _encodeKeyTuple(vec), 0, packedValue, fieldLayout);
  }

  function _set(ResourceId tableId, FieldLayout fieldLayout, Vec3 vec, bytes memory packedValue) internal {
    StoreCore.setStaticField(tableId, _encodeKeyTuple(vec), 0, packedValue, fieldLayout);
  }

  function deleteRecord(ResourceId tableId, bytes32 key) internal {
    StoreSwitch.deleteRecord(tableId, _encodeKeyTuple(key));
  }

  function _deleteRecord(ResourceId tableId, bytes32 key) internal {
    StoreCore.deleteRecord(tableId, _encodeKeyTuple(key));
  }

  function deleteRecord(ResourceId tableId, Vec3 vec) internal {
    StoreSwitch.deleteRecord(tableId, _encodeKeyTuple(vec));
  }

  function _deleteRecord(ResourceId tableId, Vec3 vec) internal {
    StoreCore.deleteRecord(tableId, _encodeKeyTuple(vec));
  }

  function _encodeKeyTuple(bytes32 key) private pure returns (bytes32[] memory keyTuple) {
    keyTuple = new bytes32[](1);
    keyTuple[0] = key;
  }

  function _encodeKeyTuple(Vec3 vec) private pure returns (bytes32[] memory keyTuple) {
    keyTuple = new bytes32[](3);
    keyTuple[0] = bytes32(uint256(int256(vec.x())));
    keyTuple[1] = bytes32(uint256(int256(vec.y())));
    keyTuple[2] = bytes32(uint256(int256(vec.z())));
  }
}

library Position {
  function get(EntityId entityId) internal view returns (Vec3 position) {
    return Vec3Storage.get(_Position._tableId, _Position._fieldLayout, entityId.unwrap());
  }

  function _get(EntityId entityId) internal view returns (Vec3 position) {
    return Vec3Storage._get(_Position._tableId, _Position._fieldLayout, entityId.unwrap());
  }

  function set(EntityId entityId, Vec3 position) internal {
    Vec3Storage.set(_Position._tableId, entityId.unwrap(), position);
  }

  function _set(EntityId entityId, Vec3 position) internal {
    Vec3Storage._set(_Position._tableId, entityId.unwrap(), position);
  }

  function deleteRecord(EntityId entityId) internal {
    Vec3Storage.deleteRecord(_Position._tableId, entityId.unwrap());
  }

  function _deleteRecord(EntityId entityId) internal {
    Vec3Storage._deleteRecord(_Position._tableId, entityId.unwrap());
  }
}

library ReversePosition {
  function get(Vec3 position) internal view returns (EntityId entityId) {
    return EntityId.wrap(Vec3Storage.get(_ReversePosition._tableId, _ReversePosition._fieldLayout, position));
  }

  function _get(Vec3 position) internal view returns (EntityId entityId) {
    return EntityId.wrap(Vec3Storage._get(_ReversePosition._tableId, _ReversePosition._fieldLayout, position));
  }

  function set(Vec3 position, EntityId entityId) internal {
    Vec3Storage.set(_ReversePosition._tableId, _ReversePosition._fieldLayout, position, abi.encodePacked(entityId));
  }

  function _set(Vec3 position, EntityId entityId) internal {
    Vec3Storage._set(_ReversePosition._tableId, _ReversePosition._fieldLayout, position, abi.encodePacked(entityId));
  }

  function deleteRecord(Vec3 position) internal {
    Vec3Storage.deleteRecord(_ReversePosition._tableId, position);
  }

  function _deleteRecord(Vec3 position) internal {
    Vec3Storage._deleteRecord(_ReversePosition._tableId, position);
  }
}

library MovablePosition {
  function get(EntityId entityId) internal view returns (Vec3 position) {
    return Vec3Storage.get(_MovablePosition._tableId, _MovablePosition._fieldLayout, entityId.unwrap());
  }

  function _get(EntityId entityId) internal view returns (Vec3 position) {
    return Vec3Storage._get(_MovablePosition._tableId, _MovablePosition._fieldLayout, entityId.unwrap());
  }

  function set(EntityId entityId, Vec3 position) internal {
    Vec3Storage.set(_MovablePosition._tableId, entityId.unwrap(), position);
  }

  function _set(EntityId entityId, Vec3 position) internal {
    Vec3Storage._set(_MovablePosition._tableId, entityId.unwrap(), position);
  }

  function deleteRecord(EntityId entityId) internal {
    Vec3Storage.deleteRecord(_MovablePosition._tableId, entityId.unwrap());
  }

  function _deleteRecord(EntityId entityId) internal {
    Vec3Storage._deleteRecord(_MovablePosition._tableId, entityId.unwrap());
  }
}

library ReverseMovablePosition {
  function get(Vec3 position) internal view returns (EntityId entityId) {
    return
      EntityId.wrap(Vec3Storage.get(_ReverseMovablePosition._tableId, _ReverseMovablePosition._fieldLayout, position));
  }

  function _get(Vec3 position) internal view returns (EntityId entityId) {
    return
      EntityId.wrap(Vec3Storage._get(_ReverseMovablePosition._tableId, _ReverseMovablePosition._fieldLayout, position));
  }

  function set(Vec3 position, EntityId entityId) internal {
    Vec3Storage.set(
      _ReverseMovablePosition._tableId, _ReverseMovablePosition._fieldLayout, position, abi.encodePacked(entityId)
    );
  }

  function _set(Vec3 position, EntityId entityId) internal {
    Vec3Storage._set(
      _ReverseMovablePosition._tableId, _ReverseMovablePosition._fieldLayout, position, abi.encodePacked(entityId)
    );
  }

  function deleteRecord(Vec3 position) internal {
    Vec3Storage.deleteRecord(_ReverseMovablePosition._tableId, position);
  }

  function _deleteRecord(Vec3 position) internal {
    Vec3Storage._deleteRecord(_ReverseMovablePosition._tableId, position);
  }
}

library InitialEnergyPool {
  function get(Vec3 position) internal view returns (uint128 value) {
    return uint128(bytes16(Vec3Storage.get(_InitialEnergyPool._tableId, _InitialEnergyPool._fieldLayout, position)));
  }

  function _get(Vec3 position) internal view returns (uint128 value) {
    return uint128(bytes16(Vec3Storage._get(_InitialEnergyPool._tableId, _InitialEnergyPool._fieldLayout, position)));
  }

  function set(Vec3 position, uint128 value) internal {
    Vec3Storage.set(_InitialEnergyPool._tableId, _InitialEnergyPool._fieldLayout, position, abi.encodePacked(value));
  }

  function _set(Vec3 position, uint128 value) internal {
    Vec3Storage._set(_InitialEnergyPool._tableId, _InitialEnergyPool._fieldLayout, position, abi.encodePacked(value));
  }

  function deleteRecord(Vec3 position) internal {
    Vec3Storage.deleteRecord(_InitialEnergyPool._tableId, position);
  }

  function _deleteRecord(Vec3 position) internal {
    Vec3Storage._deleteRecord(_InitialEnergyPool._tableId, position);
  }
}

library LocalEnergyPool {
  function get(Vec3 position) internal view returns (uint128 value) {
    return uint128(bytes16(Vec3Storage.get(_LocalEnergyPool._tableId, _LocalEnergyPool._fieldLayout, position)));
  }

  function _get(Vec3 position) internal view returns (uint128 value) {
    return uint128(bytes16(Vec3Storage._get(_LocalEnergyPool._tableId, _LocalEnergyPool._fieldLayout, position)));
  }

  function set(Vec3 position, uint128 value) internal {
    Vec3Storage.set(_LocalEnergyPool._tableId, _LocalEnergyPool._fieldLayout, position, abi.encodePacked(value));
  }

  function _set(Vec3 position, uint128 value) internal {
    Vec3Storage._set(_LocalEnergyPool._tableId, _LocalEnergyPool._fieldLayout, position, abi.encodePacked(value));
  }

  function deleteRecord(Vec3 position) internal {
    Vec3Storage.deleteRecord(_LocalEnergyPool._tableId, position);
  }

  function _deleteRecord(Vec3 position) internal {
    Vec3Storage._deleteRecord(_LocalEnergyPool._tableId, position);
  }
}

library ExploredChunk {
  function get(Vec3 position) internal view returns (address value) {
    return address(bytes20(Vec3Storage.get(_ExploredChunk._tableId, _ExploredChunk._fieldLayout, position)));
  }

  function _get(Vec3 position) internal view returns (address value) {
    return address(bytes20(Vec3Storage._get(_ExploredChunk._tableId, _ExploredChunk._fieldLayout, position)));
  }

  function set(Vec3 position, address value) internal {
    Vec3Storage.set(_ExploredChunk._tableId, _ExploredChunk._fieldLayout, position, abi.encodePacked(value));
  }

  function _set(Vec3 position, address value) internal {
    Vec3Storage._set(_ExploredChunk._tableId, _ExploredChunk._fieldLayout, position, abi.encodePacked(value));
  }

  function deleteRecord(Vec3 position) internal {
    Vec3Storage.deleteRecord(_ExploredChunk._tableId, position);
  }

  function _deleteRecord(Vec3 position) internal {
    Vec3Storage._deleteRecord(_ExploredChunk._tableId, position);
  }
}

library SurfaceChunkByIndex {
  function get(uint256 key) internal view returns (Vec3 position) {
    return Vec3Storage.get(_SurfaceChunkByIndex._tableId, _SurfaceChunkByIndex._fieldLayout, bytes32(key));
  }

  function _get(uint256 key) internal view returns (Vec3 position) {
    return Vec3Storage._get(_SurfaceChunkByIndex._tableId, _SurfaceChunkByIndex._fieldLayout, bytes32(key));
  }

  function set(uint256 key, Vec3 position) internal {
    Vec3Storage.set(_SurfaceChunkByIndex._tableId, bytes32(key), position);
  }

  function _set(uint256 key, Vec3 position) internal {
    Vec3Storage._set(_SurfaceChunkByIndex._tableId, bytes32(key), position);
  }

  function deleteRecord(uint256 key) internal {
    Vec3Storage.deleteRecord(_SurfaceChunkByIndex._tableId, bytes32(key));
  }

  function _deleteRecord(uint256 key) internal {
    Vec3Storage._deleteRecord(_SurfaceChunkByIndex._tableId, bytes32(key));
  }
}

library ForceFieldFragment {
  function get(Vec3 position) internal view returns (ForceFieldFragmentData memory value) {
    bytes memory staticData =
      Vec3Storage.getAsBytes(_ForceFieldFragment._tableId, _ForceFieldFragment._fieldLayout, position);
    (value.entityId, value.forceFieldId, value.forceFieldCreatedAt) = _ForceFieldFragment.decodeStatic(staticData);
  }

  function _get(Vec3 position) internal view returns (ForceFieldFragmentData memory value) {
    bytes memory staticData =
      Vec3Storage._getAsBytes(_ForceFieldFragment._tableId, _ForceFieldFragment._fieldLayout, position);
    (value.entityId, value.forceFieldId, value.forceFieldCreatedAt) = _ForceFieldFragment.decodeStatic(staticData);
  }

  function _getForceFieldId(Vec3 position) internal view returns (EntityId) {
    bytes32 value = Vec3Storage._getStatic(_ForceFieldFragment._tableId, _ForceFieldFragment._fieldLayout, 2, position);
    return EntityId.wrap(value);
  }

  function set(Vec3 position, ForceFieldFragmentData memory value) internal {
    bytes memory staticData =
      _ForceFieldFragment.encodeStatic(value.entityId, value.forceFieldId, value.forceFieldCreatedAt);
    Vec3Storage.set(_ForceFieldFragment._tableId, _ForceFieldFragment._fieldLayout, position, staticData);
  }

  function _set(Vec3 position, ForceFieldFragmentData memory value) internal {
    bytes memory staticData =
      _ForceFieldFragment.encodeStatic(value.entityId, value.forceFieldId, value.forceFieldCreatedAt);
    Vec3Storage._set(_ForceFieldFragment._tableId, _ForceFieldFragment._fieldLayout, position, staticData);
  }

  function deleteRecord(Vec3 position) internal {
    Vec3Storage.deleteRecord(_ForceFieldFragment._tableId, position);
  }

  function _deleteRecord(Vec3 position) internal {
    Vec3Storage._deleteRecord(_ForceFieldFragment._tableId, position);
  }
}

library ForceFieldFragmentPosition {
  function get(EntityId entityId) internal view returns (Vec3 position) {
    return
      Vec3Storage.get(_ForceFieldFragmentPosition._tableId, _ForceFieldFragmentPosition._fieldLayout, entityId.unwrap());
  }

  function _get(EntityId entityId) internal view returns (Vec3 position) {
    return Vec3Storage._get(
      _ForceFieldFragmentPosition._tableId, _ForceFieldFragmentPosition._fieldLayout, entityId.unwrap()
    );
  }

  function set(EntityId entityId, Vec3 position) internal {
    Vec3Storage.set(_ForceFieldFragmentPosition._tableId, entityId.unwrap(), position);
  }

  function _set(EntityId entityId, Vec3 position) internal {
    Vec3Storage._set(_ForceFieldFragmentPosition._tableId, entityId.unwrap(), position);
  }

  function deleteRecord(EntityId entityId) internal {
    Vec3Storage.deleteRecord(_ForceFieldFragmentPosition._tableId, entityId.unwrap());
  }

  function _deleteRecord(EntityId entityId) internal {
    Vec3Storage._deleteRecord(_ForceFieldFragmentPosition._tableId, entityId.unwrap());
  }
}

library ChunkCommitment {
  function get(Vec3 position) internal view returns (uint256 value) {
    return uint256(Vec3Storage.get(_ChunkCommitment._tableId, _ChunkCommitment._fieldLayout, position));
  }

  function _get(Vec3 position) internal view returns (uint256 value) {
    return uint256(Vec3Storage._get(_ChunkCommitment._tableId, _ChunkCommitment._fieldLayout, position));
  }

  function set(Vec3 position, uint256 value) internal {
    Vec3Storage.set(_ChunkCommitment._tableId, _ChunkCommitment._fieldLayout, position, abi.encodePacked(value));
  }

  function _set(Vec3 position, uint256 value) internal {
    Vec3Storage._set(_ChunkCommitment._tableId, _ChunkCommitment._fieldLayout, position, abi.encodePacked(value));
  }

  function deleteRecord(Vec3 position) internal {
    Vec3Storage.deleteRecord(_ChunkCommitment._tableId, position);
  }

  function _deleteRecord(Vec3 position) internal {
    Vec3Storage._deleteRecord(_ChunkCommitment._tableId, position);
  }
}

library ResourcePosition {
  function get(ObjectTypeId objectType, uint256 key) internal view returns (Vec3 position) {
    bytes32[] memory keyTuple = new bytes32[](2);
    keyTuple[0] = bytes32(uint256(ObjectTypeId.unwrap(objectType)));
    keyTuple[1] = bytes32(key);
    (bytes memory _staticData,,) =
      StoreSwitch.getRecord(_ResourcePosition._tableId, keyTuple, _ResourcePosition._fieldLayout);

    assembly {
      position := mload(add(_staticData, 0xc))
    }
  }

  function _get(ObjectTypeId objectType, uint256 key) internal view returns (Vec3 position) {
    bytes32[] memory keyTuple = new bytes32[](2);
    keyTuple[0] = bytes32(uint256(ObjectTypeId.unwrap(objectType)));
    keyTuple[1] = bytes32(key);
    (bytes memory _staticData,,) =
      StoreCore.getRecord(_ResourcePosition._tableId, keyTuple, _ResourcePosition._fieldLayout);

    assembly {
      position := mload(add(_staticData, 0xc))
    }
  }

  function set(ObjectTypeId objectType, uint256 key, Vec3 position) internal {
    bytes32[] memory keyTuple = new bytes32[](2);
    keyTuple[0] = bytes32(uint256(ObjectTypeId.unwrap(objectType)));
    keyTuple[1] = bytes32(key);

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;
    StoreSwitch.setRecord(
      _ResourcePosition._tableId, keyTuple, abi.encodePacked(position), _encodedLengths, _dynamicData
    );
  }

  function _set(ObjectTypeId objectType, uint256 key, Vec3 position) internal {
    bytes32[] memory keyTuple = new bytes32[](2);
    keyTuple[0] = bytes32(uint256(ObjectTypeId.unwrap(objectType)));
    keyTuple[1] = bytes32(key);

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;
    StoreCore.setRecord(_ResourcePosition._tableId, keyTuple, abi.encodePacked(position), _encodedLengths, _dynamicData);
  }

  function deleteRecord(ObjectTypeId objectType, uint256 key) internal {
    bytes32[] memory keyTuple = new bytes32[](2);
    keyTuple[0] = bytes32(uint256(ObjectTypeId.unwrap(objectType)));
    keyTuple[1] = bytes32(key);

    StoreSwitch.deleteRecord(_ResourcePosition._tableId, keyTuple);
  }

  function _deleteRecord(ObjectTypeId objectType, uint256 key) internal {
    bytes32[] memory keyTuple = new bytes32[](2);
    keyTuple[0] = bytes32(uint256(ObjectTypeId.unwrap(objectType)));
    keyTuple[1] = bytes32(key);

    StoreCore.deleteRecord(_ResourcePosition._tableId, keyTuple, _ResourcePosition._fieldLayout);
  }
}
