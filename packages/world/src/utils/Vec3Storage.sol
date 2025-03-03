// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { StoreCore } from "@latticexyz/store/src/StoreCore.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { FieldLayout } from "@latticexyz/store/src/FieldLayout.sol";
import { EncodedLengths } from "@latticexyz/store/src/EncodedLengths.sol";

import { Position as _Position } from "../codegen/tables/Position.sol";
import { ReversePosition as _ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { PlayerPosition as _PlayerPosition } from "../codegen/tables/PlayerPosition.sol";
import { ReversePlayerPosition as _ReversePlayerPosition } from "../codegen/tables/ReversePlayerPosition.sol";
import { InitialEnergyPool as _InitialEnergyPool } from "../codegen/tables/InitialEnergyPool.sol";
import { LocalEnergyPool as _LocalEnergyPool } from "../codegen/tables/LocalEnergyPool.sol";
import { ExploredChunk as _ExploredChunk } from "../codegen/tables/ExploredChunk.sol";
import { ExploredChunkByIndex as _ExploredChunkByIndex } from "../codegen/tables/ExploredChunkByIndex.sol";
import { ForceField as _ForceField } from "../codegen/tables/ForceField.sol";
import { ForceFieldMetadata as _ForceFieldMetadata } from "../codegen/tables/ForceFieldMetadata.sol";
import { OreCommitment as _OreCommitment } from "../codegen/tables/OreCommitment.sol";
import { MinedOrePosition as _MinedOrePosition } from "../codegen/tables/MinedOrePosition.sol";

import { EntityId } from "../EntityId.sol";
import { Vec3 } from "../Vec3.sol";

/// @dev Library to get and set Vec3s in tables. It only support schemas of <single key> -> Vec3 and Vec3 -> <single value>
library Vec3Storage {
  function get(ResourceId tableId, FieldLayout fieldLayout, bytes32 key) internal view returns (Vec3 output) {
    (bytes memory _staticData, , ) = StoreSwitch.getRecord(tableId, _encodeKeyTuple(key), fieldLayout);

    assembly {
      output := mload(add(_staticData, 0x20))
    }
  }

  function _get(ResourceId tableId, FieldLayout fieldLayout, bytes32 key) internal view returns (Vec3 output) {
    (bytes memory _staticData, , ) = StoreCore.getRecord(tableId, _encodeKeyTuple(key), fieldLayout);

    assembly {
      output := mload(add(_staticData, 0x20))
    }
  }

  function get(ResourceId tableId, FieldLayout fieldLayout, Vec3 vec) internal view returns (bytes32) {
    return StoreSwitch.getStaticField(tableId, _encodeKeyTuple(vec), 0, fieldLayout);
  }

  function _get(ResourceId tableId, FieldLayout fieldLayout, Vec3 vec) internal view returns (bytes32) {
    return StoreCore.getStaticField(tableId, _encodeKeyTuple(vec), 0, fieldLayout);
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

library PlayerPosition {
  function get(EntityId entityId) internal view returns (Vec3 position) {
    return Vec3Storage.get(_PlayerPosition._tableId, _PlayerPosition._fieldLayout, entityId.unwrap());
  }

  function _get(EntityId entityId) internal view returns (Vec3 position) {
    return Vec3Storage._get(_PlayerPosition._tableId, _PlayerPosition._fieldLayout, entityId.unwrap());
  }

  function set(EntityId entityId, Vec3 position) internal {
    Vec3Storage.set(_PlayerPosition._tableId, entityId.unwrap(), position);
  }

  function _set(EntityId entityId, Vec3 position) internal {
    Vec3Storage._set(_PlayerPosition._tableId, entityId.unwrap(), position);
  }

  function deleteRecord(EntityId entityId) internal {
    Vec3Storage.deleteRecord(_PlayerPosition._tableId, entityId.unwrap());
  }

  function _deleteRecord(EntityId entityId) internal {
    Vec3Storage._deleteRecord(_PlayerPosition._tableId, entityId.unwrap());
  }
}

library ReversePlayerPosition {
  function get(Vec3 position) internal view returns (EntityId entityId) {
    return
      EntityId.wrap(Vec3Storage.get(_ReversePlayerPosition._tableId, _ReversePlayerPosition._fieldLayout, position));
  }

  function _get(Vec3 position) internal view returns (EntityId entityId) {
    return
      EntityId.wrap(Vec3Storage._get(_ReversePlayerPosition._tableId, _ReversePlayerPosition._fieldLayout, position));
  }

  function set(Vec3 position, EntityId entityId) internal {
    Vec3Storage.set(
      _ReversePlayerPosition._tableId,
      _ReversePlayerPosition._fieldLayout,
      position,
      abi.encodePacked(entityId)
    );
  }

  function _set(Vec3 position, EntityId entityId) internal {
    Vec3Storage._set(
      _ReversePlayerPosition._tableId,
      _ReversePlayerPosition._fieldLayout,
      position,
      abi.encodePacked(entityId)
    );
  }

  function deleteRecord(Vec3 position) internal {
    Vec3Storage.deleteRecord(_ReversePlayerPosition._tableId, position);
  }

  function _deleteRecord(Vec3 position) internal {
    Vec3Storage._deleteRecord(_ReversePlayerPosition._tableId, position);
  }
}

library InitialEnergyPool {
  function get(Vec3 position) internal view returns (uint128 value) {
    return uint128(uint256(Vec3Storage.get(_InitialEnergyPool._tableId, _InitialEnergyPool._fieldLayout, position)));
  }

  function _get(Vec3 position) internal view returns (uint128 value) {
    return uint128(uint256(Vec3Storage._get(_InitialEnergyPool._tableId, _InitialEnergyPool._fieldLayout, position)));
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
    return uint128(uint256(Vec3Storage.get(_LocalEnergyPool._tableId, _LocalEnergyPool._fieldLayout, position)));
  }

  function _get(Vec3 position) internal view returns (uint128 value) {
    return uint128(uint256(Vec3Storage._get(_LocalEnergyPool._tableId, _LocalEnergyPool._fieldLayout, position)));
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
    return address(uint160(uint256(Vec3Storage.get(_ExploredChunk._tableId, _ExploredChunk._fieldLayout, position))));
  }

  function _get(Vec3 position) internal view returns (address value) {
    return address(uint160(uint256(Vec3Storage._get(_ExploredChunk._tableId, _ExploredChunk._fieldLayout, position))));
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

library ExploredChunkByIndex {
  function get(uint256 key) internal view returns (Vec3 position) {
    return Vec3Storage.get(_ExploredChunkByIndex._tableId, _ExploredChunkByIndex._fieldLayout, bytes32(key));
  }

  function _get(uint256 key) internal view returns (Vec3 position) {
    return Vec3Storage._get(_ExploredChunkByIndex._tableId, _ExploredChunkByIndex._fieldLayout, bytes32(key));
  }

  function set(uint256 key, Vec3 position) internal {
    Vec3Storage.set(_ExploredChunkByIndex._tableId, bytes32(key), position);
  }

  function _set(uint256 key, Vec3 position) internal {
    Vec3Storage._set(_ExploredChunkByIndex._tableId, bytes32(key), position);
  }

  function deleteRecord(uint256 key) internal {
    Vec3Storage.deleteRecord(_ExploredChunkByIndex._tableId, bytes32(key));
  }

  function _deleteRecord(uint256 key) internal {
    Vec3Storage._deleteRecord(_ExploredChunkByIndex._tableId, bytes32(key));
  }
}

library ForceField {
  function get(Vec3 position) internal view returns (EntityId value) {
    return EntityId.wrap(Vec3Storage.get(_ForceField._tableId, _ForceField._fieldLayout, position));
  }

  function _get(Vec3 position) internal view returns (EntityId value) {
    return EntityId.wrap(Vec3Storage._get(_ForceField._tableId, _ForceField._fieldLayout, position));
  }

  function set(Vec3 position, EntityId value) internal {
    Vec3Storage.set(_ForceField._tableId, _ForceField._fieldLayout, position, abi.encodePacked(value));
  }

  function _set(Vec3 position, EntityId value) internal {
    Vec3Storage._set(_ForceField._tableId, _ForceField._fieldLayout, position, abi.encodePacked(value));
  }

  function deleteRecord(Vec3 position) internal {
    Vec3Storage.deleteRecord(_ForceField._tableId, position);
  }

  function _deleteRecord(Vec3 position) internal {
    Vec3Storage._deleteRecord(_ForceField._tableId, position);
  }
}

library ForceFieldMetadata {
  function get(Vec3 position) internal view returns (uint128 value) {
    return uint128(uint256(Vec3Storage.get(_ForceFieldMetadata._tableId, _ForceFieldMetadata._fieldLayout, position)));
  }

  function _get(Vec3 position) internal view returns (uint128 value) {
    return uint128(uint256(Vec3Storage._get(_ForceFieldMetadata._tableId, _ForceFieldMetadata._fieldLayout, position)));
  }

  function getTotalMassInside(Vec3 position) internal view returns (uint128 value) {
    return get(position);
  }

  function _getTotalMassInside(Vec3 position) internal view returns (uint128 value) {
    return _get(position);
  }

  function set(Vec3 position, uint128 value) internal {
    Vec3Storage.set(_ForceFieldMetadata._tableId, _ForceFieldMetadata._fieldLayout, position, abi.encodePacked(value));
  }

  function _set(Vec3 position, uint128 value) internal {
    Vec3Storage._set(_ForceFieldMetadata._tableId, _ForceFieldMetadata._fieldLayout, position, abi.encodePacked(value));
  }

  function setTotalMassInside(Vec3 position, uint128 value) internal {
    set(position, value);
  }

  function _setTotalMassInside(Vec3 position, uint128 value) internal {
    _set(position, value);
  }

  function deleteRecord(Vec3 position) internal {
    Vec3Storage.deleteRecord(_ForceFieldMetadata._tableId, position);
  }

  function _deleteRecord(Vec3 position) internal {
    Vec3Storage._deleteRecord(_ForceFieldMetadata._tableId, position);
  }
}

library OreCommitment {
  function get(Vec3 position) internal view returns (uint256 value) {
    return uint256(Vec3Storage.get(_OreCommitment._tableId, _OreCommitment._fieldLayout, position));
  }

  function _get(Vec3 position) internal view returns (uint256 value) {
    return uint256(Vec3Storage._get(_OreCommitment._tableId, _OreCommitment._fieldLayout, position));
  }

  function set(Vec3 position, uint256 value) internal {
    Vec3Storage.set(_OreCommitment._tableId, _OreCommitment._fieldLayout, position, abi.encodePacked(value));
  }

  function _set(Vec3 position, uint256 value) internal {
    Vec3Storage._set(_OreCommitment._tableId, _OreCommitment._fieldLayout, position, abi.encodePacked(value));
  }

  function deleteRecord(Vec3 position) internal {
    Vec3Storage.deleteRecord(_OreCommitment._tableId, position);
  }

  function _deleteRecord(Vec3 position) internal {
    Vec3Storage._deleteRecord(_OreCommitment._tableId, position);
  }
}

library MinedOrePosition {
  function get(uint256 key) internal view returns (Vec3 position) {
    return Vec3Storage.get(_MinedOrePosition._tableId, _MinedOrePosition._fieldLayout, bytes32(key));
  }

  function _get(uint256 key) internal view returns (Vec3 position) {
    return Vec3Storage._get(_MinedOrePosition._tableId, _MinedOrePosition._fieldLayout, bytes32(key));
  }

  function set(uint256 key, Vec3 position) internal {
    Vec3Storage.set(_MinedOrePosition._tableId, bytes32(key), position);
  }

  function _set(uint256 key, Vec3 position) internal {
    Vec3Storage._set(_MinedOrePosition._tableId, bytes32(key), position);
  }

  function deleteRecord(uint256 key) internal {
    Vec3Storage.deleteRecord(_MinedOrePosition._tableId, bytes32(key));
  }

  function _deleteRecord(uint256 key) internal {
    Vec3Storage._deleteRecord(_MinedOrePosition._tableId, bytes32(key));
  }
}
