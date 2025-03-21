// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

// Import store internals
import { IStore } from "@latticexyz/store/src/IStore.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { StoreCore } from "@latticexyz/store/src/StoreCore.sol";
import { Bytes } from "@latticexyz/store/src/Bytes.sol";
import { Memory } from "@latticexyz/store/src/Memory.sol";
import { SliceLib } from "@latticexyz/store/src/Slice.sol";
import { EncodeArray } from "@latticexyz/store/src/tightcoder/EncodeArray.sol";
import { FieldLayout } from "@latticexyz/store/src/FieldLayout.sol";
import { Schema } from "@latticexyz/store/src/Schema.sol";
import { EncodedLengths, EncodedLengthsLib } from "@latticexyz/store/src/EncodedLengths.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";

// Import user types
import { EntityId } from "../../EntityId.sol";

library ReverseInventoryEntity {
  // Hex below is the result of `WorldResourceIdLib.encode({ namespace: "", name: "ReverseInventory", typeId: RESOURCE_TABLE });`
  ResourceId constant _tableId = ResourceId.wrap(0x7462000000000000000000000000000052657665727365496e76656e746f7279);

  FieldLayout constant _fieldLayout =
    FieldLayout.wrap(0x0000000100000000000000000000000000000000000000000000000000000000);

  // Hex-encoded key schema of (bytes32)
  Schema constant _keySchema = Schema.wrap(0x002001005f000000000000000000000000000000000000000000000000000000);
  // Hex-encoded value schema of (bytes32[])
  Schema constant _valueSchema = Schema.wrap(0x00000001c1000000000000000000000000000000000000000000000000000000);

  /**
   * @notice Get the table's key field names.
   * @return keyNames An array of strings with the names of key fields.
   */
  function getKeyNames() internal pure returns (string[] memory keyNames) {
    keyNames = new string[](1);
    keyNames[0] = "ownerEntityId";
  }

  /**
   * @notice Get the table's value field names.
   * @return fieldNames An array of strings with the names of value fields.
   */
  function getFieldNames() internal pure returns (string[] memory fieldNames) {
    fieldNames = new string[](1);
    fieldNames[0] = "entityIds";
  }

  /**
   * @notice Register the table with its config.
   */
  function register() internal {
    StoreSwitch.registerTable(_tableId, _fieldLayout, _keySchema, _valueSchema, getKeyNames(), getFieldNames());
  }

  /**
   * @notice Register the table with its config.
   */
  function _register() internal {
    StoreCore.registerTable(_tableId, _fieldLayout, _keySchema, _valueSchema, getKeyNames(), getFieldNames());
  }

  /**
   * @notice Get entityIds.
   */
  function getEntityIds(EntityId ownerEntityId) internal view returns (bytes32[] memory entityIds) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    bytes memory _blob = StoreSwitch.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes32());
  }

  /**
   * @notice Get entityIds.
   */
  function _getEntityIds(EntityId ownerEntityId) internal view returns (bytes32[] memory entityIds) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    bytes memory _blob = StoreCore.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes32());
  }

  /**
   * @notice Get entityIds.
   */
  function get(EntityId ownerEntityId) internal view returns (bytes32[] memory entityIds) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    bytes memory _blob = StoreSwitch.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes32());
  }

  /**
   * @notice Get entityIds.
   */
  function _get(EntityId ownerEntityId) internal view returns (bytes32[] memory entityIds) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    bytes memory _blob = StoreCore.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes32());
  }

  /**
   * @notice Set entityIds.
   */
  function setEntityIds(EntityId ownerEntityId, bytes32[] memory entityIds) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    StoreSwitch.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((entityIds)));
  }

  /**
   * @notice Set entityIds.
   */
  function _setEntityIds(EntityId ownerEntityId, bytes32[] memory entityIds) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    StoreCore.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((entityIds)));
  }

  /**
   * @notice Set entityIds.
   */
  function set(EntityId ownerEntityId, bytes32[] memory entityIds) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    StoreSwitch.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((entityIds)));
  }

  /**
   * @notice Set entityIds.
   */
  function _set(EntityId ownerEntityId, bytes32[] memory entityIds) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    StoreCore.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((entityIds)));
  }

  /**
   * @notice Get the length of entityIds.
   */
  function lengthEntityIds(EntityId ownerEntityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    uint256 _byteLength = StoreSwitch.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 32;
    }
  }

  /**
   * @notice Get the length of entityIds.
   */
  function _lengthEntityIds(EntityId ownerEntityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    uint256 _byteLength = StoreCore.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 32;
    }
  }

  /**
   * @notice Get the length of entityIds.
   */
  function length(EntityId ownerEntityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    uint256 _byteLength = StoreSwitch.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 32;
    }
  }

  /**
   * @notice Get the length of entityIds.
   */
  function _length(EntityId ownerEntityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    uint256 _byteLength = StoreCore.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 32;
    }
  }

  /**
   * @notice Get an item of entityIds.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItemEntityIds(EntityId ownerEntityId, uint256 _index) internal view returns (bytes32) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    unchecked {
      bytes memory _blob = StoreSwitch.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 32, (_index + 1) * 32);
      return (bytes32(_blob));
    }
  }

  /**
   * @notice Get an item of entityIds.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function _getItemEntityIds(EntityId ownerEntityId, uint256 _index) internal view returns (bytes32) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    unchecked {
      bytes memory _blob = StoreCore.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 32, (_index + 1) * 32);
      return (bytes32(_blob));
    }
  }

  /**
   * @notice Get an item of entityIds.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItem(EntityId ownerEntityId, uint256 _index) internal view returns (bytes32) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    unchecked {
      bytes memory _blob = StoreSwitch.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 32, (_index + 1) * 32);
      return (bytes32(_blob));
    }
  }

  /**
   * @notice Get an item of entityIds.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function _getItem(EntityId ownerEntityId, uint256 _index) internal view returns (bytes32) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    unchecked {
      bytes memory _blob = StoreCore.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 32, (_index + 1) * 32);
      return (bytes32(_blob));
    }
  }

  /**
   * @notice Push an element to entityIds.
   */
  function pushEntityIds(EntityId ownerEntityId, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    StoreSwitch.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to entityIds.
   */
  function _pushEntityIds(EntityId ownerEntityId, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    StoreCore.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to entityIds.
   */
  function push(EntityId ownerEntityId, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    StoreSwitch.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to entityIds.
   */
  function _push(EntityId ownerEntityId, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    StoreCore.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Pop an element from entityIds.
   */
  function popEntityIds(EntityId ownerEntityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    StoreSwitch.popFromDynamicField(_tableId, _keyTuple, 0, 32);
  }

  /**
   * @notice Pop an element from entityIds.
   */
  function _popEntityIds(EntityId ownerEntityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    StoreCore.popFromDynamicField(_tableId, _keyTuple, 0, 32);
  }

  /**
   * @notice Pop an element from entityIds.
   */
  function pop(EntityId ownerEntityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    StoreSwitch.popFromDynamicField(_tableId, _keyTuple, 0, 32);
  }

  /**
   * @notice Pop an element from entityIds.
   */
  function _pop(EntityId ownerEntityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    StoreCore.popFromDynamicField(_tableId, _keyTuple, 0, 32);
  }

  /**
   * @notice Update an element of entityIds at `_index`.
   */
  function updateEntityIds(EntityId ownerEntityId, uint256 _index, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreSwitch.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 32), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of entityIds at `_index`.
   */
  function _updateEntityIds(EntityId ownerEntityId, uint256 _index, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreCore.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 32), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of entityIds at `_index`.
   */
  function update(EntityId ownerEntityId, uint256 _index, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreSwitch.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 32), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of entityIds at `_index`.
   */
  function _update(EntityId ownerEntityId, uint256 _index, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreCore.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 32), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Delete all data for given keys.
   */
  function deleteRecord(EntityId ownerEntityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    StoreSwitch.deleteRecord(_tableId, _keyTuple);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function _deleteRecord(EntityId ownerEntityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    StoreCore.deleteRecord(_tableId, _keyTuple, _fieldLayout);
  }

  /**
   * @notice Tightly pack dynamic data lengths using this table's schema.
   * @return _encodedLengths The lengths of the dynamic fields (packed into a single bytes32 value).
   */
  function encodeLengths(bytes32[] memory entityIds) internal pure returns (EncodedLengths _encodedLengths) {
    // Lengths are effectively checked during copy by 2**40 bytes exceeding gas limits
    unchecked {
      _encodedLengths = EncodedLengthsLib.pack(entityIds.length * 32);
    }
  }

  /**
   * @notice Tightly pack dynamic (variable length) data using this table's schema.
   * @return The dynamic data, encoded into a sequence of bytes.
   */
  function encodeDynamic(bytes32[] memory entityIds) internal pure returns (bytes memory) {
    return abi.encodePacked(EncodeArray.encode((entityIds)));
  }

  /**
   * @notice Encode all of a record's fields.
   * @return The static (fixed length) data, encoded into a sequence of bytes.
   * @return The lengths of the dynamic fields (packed into a single bytes32 value).
   * @return The dynamic (variable length) data, encoded into a sequence of bytes.
   */
  function encode(bytes32[] memory entityIds) internal pure returns (bytes memory, EncodedLengths, bytes memory) {
    bytes memory _staticData;
    EncodedLengths _encodedLengths = encodeLengths(entityIds);
    bytes memory _dynamicData = encodeDynamic(entityIds);

    return (_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Encode keys as a bytes32 array using this table's field layout.
   */
  function encodeKeyTuple(EntityId ownerEntityId) internal pure returns (bytes32[] memory) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(ownerEntityId);

    return _keyTuple;
  }
}
