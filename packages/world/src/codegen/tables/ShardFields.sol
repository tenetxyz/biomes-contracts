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

library ShardFields {
  // Hex below is the result of `WorldResourceIdLib.encode({ namespace: "", name: "ShardFields", typeId: RESOURCE_TABLE });`
  ResourceId constant _tableId = ResourceId.wrap(0x7462000000000000000000000000000053686172644669656c64730000000000);

  FieldLayout constant _fieldLayout =
    FieldLayout.wrap(0x0000000100000000000000000000000000000000000000000000000000000000);

  // Hex-encoded key schema of (int16, int16)
  Schema constant _keySchema = Schema.wrap(0x0004020021210000000000000000000000000000000000000000000000000000);
  // Hex-encoded value schema of (bytes32[])
  Schema constant _valueSchema = Schema.wrap(0x00000001c1000000000000000000000000000000000000000000000000000000);

  /**
   * @notice Get the table's key field names.
   * @return keyNames An array of strings with the names of key fields.
   */
  function getKeyNames() internal pure returns (string[] memory keyNames) {
    keyNames = new string[](2);
    keyNames[0] = "x";
    keyNames[1] = "z";
  }

  /**
   * @notice Get the table's value field names.
   * @return fieldNames An array of strings with the names of value fields.
   */
  function getFieldNames() internal pure returns (string[] memory fieldNames) {
    fieldNames = new string[](1);
    fieldNames[0] = "forceFieldEntityIds";
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
   * @notice Register the table with its config (using the specified store).
   */
  function register(IStore _store) internal {
    _store.registerTable(_tableId, _fieldLayout, _keySchema, _valueSchema, getKeyNames(), getFieldNames());
  }

  /**
   * @notice Get forceFieldEntityIds.
   */
  function getForceFieldEntityIds(int16 x, int16 z) internal view returns (bytes32[] memory forceFieldEntityIds) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    bytes memory _blob = StoreSwitch.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes32());
  }

  /**
   * @notice Get forceFieldEntityIds.
   */
  function _getForceFieldEntityIds(int16 x, int16 z) internal view returns (bytes32[] memory forceFieldEntityIds) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    bytes memory _blob = StoreCore.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes32());
  }

  /**
   * @notice Get forceFieldEntityIds (using the specified store).
   */
  function getForceFieldEntityIds(
    IStore _store,
    int16 x,
    int16 z
  ) internal view returns (bytes32[] memory forceFieldEntityIds) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    bytes memory _blob = _store.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes32());
  }

  /**
   * @notice Get forceFieldEntityIds.
   */
  function get(int16 x, int16 z) internal view returns (bytes32[] memory forceFieldEntityIds) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    bytes memory _blob = StoreSwitch.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes32());
  }

  /**
   * @notice Get forceFieldEntityIds.
   */
  function _get(int16 x, int16 z) internal view returns (bytes32[] memory forceFieldEntityIds) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    bytes memory _blob = StoreCore.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes32());
  }

  /**
   * @notice Get forceFieldEntityIds (using the specified store).
   */
  function get(IStore _store, int16 x, int16 z) internal view returns (bytes32[] memory forceFieldEntityIds) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    bytes memory _blob = _store.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes32());
  }

  /**
   * @notice Set forceFieldEntityIds.
   */
  function setForceFieldEntityIds(int16 x, int16 z, bytes32[] memory forceFieldEntityIds) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    StoreSwitch.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((forceFieldEntityIds)));
  }

  /**
   * @notice Set forceFieldEntityIds.
   */
  function _setForceFieldEntityIds(int16 x, int16 z, bytes32[] memory forceFieldEntityIds) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    StoreCore.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((forceFieldEntityIds)));
  }

  /**
   * @notice Set forceFieldEntityIds (using the specified store).
   */
  function setForceFieldEntityIds(IStore _store, int16 x, int16 z, bytes32[] memory forceFieldEntityIds) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    _store.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((forceFieldEntityIds)));
  }

  /**
   * @notice Set forceFieldEntityIds.
   */
  function set(int16 x, int16 z, bytes32[] memory forceFieldEntityIds) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    StoreSwitch.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((forceFieldEntityIds)));
  }

  /**
   * @notice Set forceFieldEntityIds.
   */
  function _set(int16 x, int16 z, bytes32[] memory forceFieldEntityIds) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    StoreCore.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((forceFieldEntityIds)));
  }

  /**
   * @notice Set forceFieldEntityIds (using the specified store).
   */
  function set(IStore _store, int16 x, int16 z, bytes32[] memory forceFieldEntityIds) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    _store.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((forceFieldEntityIds)));
  }

  /**
   * @notice Get the length of forceFieldEntityIds.
   */
  function lengthForceFieldEntityIds(int16 x, int16 z) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    uint256 _byteLength = StoreSwitch.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 32;
    }
  }

  /**
   * @notice Get the length of forceFieldEntityIds.
   */
  function _lengthForceFieldEntityIds(int16 x, int16 z) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    uint256 _byteLength = StoreCore.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 32;
    }
  }

  /**
   * @notice Get the length of forceFieldEntityIds (using the specified store).
   */
  function lengthForceFieldEntityIds(IStore _store, int16 x, int16 z) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    uint256 _byteLength = _store.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 32;
    }
  }

  /**
   * @notice Get the length of forceFieldEntityIds.
   */
  function length(int16 x, int16 z) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    uint256 _byteLength = StoreSwitch.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 32;
    }
  }

  /**
   * @notice Get the length of forceFieldEntityIds.
   */
  function _length(int16 x, int16 z) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    uint256 _byteLength = StoreCore.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 32;
    }
  }

  /**
   * @notice Get the length of forceFieldEntityIds (using the specified store).
   */
  function length(IStore _store, int16 x, int16 z) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    uint256 _byteLength = _store.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 32;
    }
  }

  /**
   * @notice Get an item of forceFieldEntityIds.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItemForceFieldEntityIds(int16 x, int16 z, uint256 _index) internal view returns (bytes32) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    unchecked {
      bytes memory _blob = StoreSwitch.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 32, (_index + 1) * 32);
      return (bytes32(_blob));
    }
  }

  /**
   * @notice Get an item of forceFieldEntityIds.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function _getItemForceFieldEntityIds(int16 x, int16 z, uint256 _index) internal view returns (bytes32) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    unchecked {
      bytes memory _blob = StoreCore.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 32, (_index + 1) * 32);
      return (bytes32(_blob));
    }
  }

  /**
   * @notice Get an item of forceFieldEntityIds (using the specified store).
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItemForceFieldEntityIds(IStore _store, int16 x, int16 z, uint256 _index) internal view returns (bytes32) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    unchecked {
      bytes memory _blob = _store.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 32, (_index + 1) * 32);
      return (bytes32(_blob));
    }
  }

  /**
   * @notice Get an item of forceFieldEntityIds.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItem(int16 x, int16 z, uint256 _index) internal view returns (bytes32) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    unchecked {
      bytes memory _blob = StoreSwitch.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 32, (_index + 1) * 32);
      return (bytes32(_blob));
    }
  }

  /**
   * @notice Get an item of forceFieldEntityIds.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function _getItem(int16 x, int16 z, uint256 _index) internal view returns (bytes32) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    unchecked {
      bytes memory _blob = StoreCore.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 32, (_index + 1) * 32);
      return (bytes32(_blob));
    }
  }

  /**
   * @notice Get an item of forceFieldEntityIds (using the specified store).
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItem(IStore _store, int16 x, int16 z, uint256 _index) internal view returns (bytes32) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    unchecked {
      bytes memory _blob = _store.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 32, (_index + 1) * 32);
      return (bytes32(_blob));
    }
  }

  /**
   * @notice Push an element to forceFieldEntityIds.
   */
  function pushForceFieldEntityIds(int16 x, int16 z, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    StoreSwitch.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to forceFieldEntityIds.
   */
  function _pushForceFieldEntityIds(int16 x, int16 z, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    StoreCore.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to forceFieldEntityIds (using the specified store).
   */
  function pushForceFieldEntityIds(IStore _store, int16 x, int16 z, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    _store.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to forceFieldEntityIds.
   */
  function push(int16 x, int16 z, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    StoreSwitch.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to forceFieldEntityIds.
   */
  function _push(int16 x, int16 z, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    StoreCore.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to forceFieldEntityIds (using the specified store).
   */
  function push(IStore _store, int16 x, int16 z, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    _store.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Pop an element from forceFieldEntityIds.
   */
  function popForceFieldEntityIds(int16 x, int16 z) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    StoreSwitch.popFromDynamicField(_tableId, _keyTuple, 0, 32);
  }

  /**
   * @notice Pop an element from forceFieldEntityIds.
   */
  function _popForceFieldEntityIds(int16 x, int16 z) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    StoreCore.popFromDynamicField(_tableId, _keyTuple, 0, 32);
  }

  /**
   * @notice Pop an element from forceFieldEntityIds (using the specified store).
   */
  function popForceFieldEntityIds(IStore _store, int16 x, int16 z) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    _store.popFromDynamicField(_tableId, _keyTuple, 0, 32);
  }

  /**
   * @notice Pop an element from forceFieldEntityIds.
   */
  function pop(int16 x, int16 z) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    StoreSwitch.popFromDynamicField(_tableId, _keyTuple, 0, 32);
  }

  /**
   * @notice Pop an element from forceFieldEntityIds.
   */
  function _pop(int16 x, int16 z) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    StoreCore.popFromDynamicField(_tableId, _keyTuple, 0, 32);
  }

  /**
   * @notice Pop an element from forceFieldEntityIds (using the specified store).
   */
  function pop(IStore _store, int16 x, int16 z) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    _store.popFromDynamicField(_tableId, _keyTuple, 0, 32);
  }

  /**
   * @notice Update an element of forceFieldEntityIds at `_index`.
   */
  function updateForceFieldEntityIds(int16 x, int16 z, uint256 _index, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreSwitch.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 32), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of forceFieldEntityIds at `_index`.
   */
  function _updateForceFieldEntityIds(int16 x, int16 z, uint256 _index, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreCore.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 32), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of forceFieldEntityIds (using the specified store) at `_index`.
   */
  function updateForceFieldEntityIds(IStore _store, int16 x, int16 z, uint256 _index, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      _store.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 32), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of forceFieldEntityIds at `_index`.
   */
  function update(int16 x, int16 z, uint256 _index, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreSwitch.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 32), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of forceFieldEntityIds at `_index`.
   */
  function _update(int16 x, int16 z, uint256 _index, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreCore.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 32), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of forceFieldEntityIds (using the specified store) at `_index`.
   */
  function update(IStore _store, int16 x, int16 z, uint256 _index, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      _store.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 32), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Delete all data for given keys.
   */
  function deleteRecord(int16 x, int16 z) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    StoreSwitch.deleteRecord(_tableId, _keyTuple);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function _deleteRecord(int16 x, int16 z) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    StoreCore.deleteRecord(_tableId, _keyTuple, _fieldLayout);
  }

  /**
   * @notice Delete all data for given keys (using the specified store).
   */
  function deleteRecord(IStore _store, int16 x, int16 z) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    _store.deleteRecord(_tableId, _keyTuple);
  }

  /**
   * @notice Tightly pack dynamic data lengths using this table's schema.
   * @return _encodedLengths The lengths of the dynamic fields (packed into a single bytes32 value).
   */
  function encodeLengths(bytes32[] memory forceFieldEntityIds) internal pure returns (EncodedLengths _encodedLengths) {
    // Lengths are effectively checked during copy by 2**40 bytes exceeding gas limits
    unchecked {
      _encodedLengths = EncodedLengthsLib.pack(forceFieldEntityIds.length * 32);
    }
  }

  /**
   * @notice Tightly pack dynamic (variable length) data using this table's schema.
   * @return The dynamic data, encoded into a sequence of bytes.
   */
  function encodeDynamic(bytes32[] memory forceFieldEntityIds) internal pure returns (bytes memory) {
    return abi.encodePacked(EncodeArray.encode((forceFieldEntityIds)));
  }

  /**
   * @notice Encode all of a record's fields.
   * @return The static (fixed length) data, encoded into a sequence of bytes.
   * @return The lengths of the dynamic fields (packed into a single bytes32 value).
   * @return The dynamic (variable length) data, encoded into a sequence of bytes.
   */
  function encode(
    bytes32[] memory forceFieldEntityIds
  ) internal pure returns (bytes memory, EncodedLengths, bytes memory) {
    bytes memory _staticData;
    EncodedLengths _encodedLengths = encodeLengths(forceFieldEntityIds);
    bytes memory _dynamicData = encodeDynamic(forceFieldEntityIds);

    return (_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Encode keys as a bytes32 array using this table's field layout.
   */
  function encodeKeyTuple(int16 x, int16 z) internal pure returns (bytes32[] memory) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = bytes32(uint256(int256(x)));
    _keyTuple[1] = bytes32(uint256(int256(z)));

    return _keyTuple;
  }
}