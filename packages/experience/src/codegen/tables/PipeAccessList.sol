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
import { EntityId } from "@biomesaw/world/src/EntityId.sol";

library PipeAccessList {
  // Hex below is the result of `WorldResourceIdLib.encode({ namespace: "experience", name: "PipeAccessList", typeId: RESOURCE_TABLE });`
  ResourceId constant _tableId = ResourceId.wrap(0x7462657870657269656e636500000000506970654163636573734c6973740000);

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
    keyNames[0] = "entityId";
  }

  /**
   * @notice Get the table's value field names.
   * @return fieldNames An array of strings with the names of value fields.
   */
  function getFieldNames() internal pure returns (string[] memory fieldNames) {
    fieldNames = new string[](1);
    fieldNames[0] = "allowedEntityIds";
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
   * @notice Get allowedEntityIds.
   */
  function getAllowedEntityIds(EntityId entityId) internal view returns (bytes32[] memory allowedEntityIds) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    bytes memory _blob = StoreSwitch.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes32());
  }

  /**
   * @notice Get allowedEntityIds.
   */
  function _getAllowedEntityIds(EntityId entityId) internal view returns (bytes32[] memory allowedEntityIds) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    bytes memory _blob = StoreCore.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes32());
  }

  /**
   * @notice Get allowedEntityIds (using the specified store).
   */
  function getAllowedEntityIds(
    IStore _store,
    EntityId entityId
  ) internal view returns (bytes32[] memory allowedEntityIds) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    bytes memory _blob = _store.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes32());
  }

  /**
   * @notice Get allowedEntityIds.
   */
  function get(EntityId entityId) internal view returns (bytes32[] memory allowedEntityIds) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    bytes memory _blob = StoreSwitch.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes32());
  }

  /**
   * @notice Get allowedEntityIds.
   */
  function _get(EntityId entityId) internal view returns (bytes32[] memory allowedEntityIds) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    bytes memory _blob = StoreCore.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes32());
  }

  /**
   * @notice Get allowedEntityIds (using the specified store).
   */
  function get(IStore _store, EntityId entityId) internal view returns (bytes32[] memory allowedEntityIds) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    bytes memory _blob = _store.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes32());
  }

  /**
   * @notice Set allowedEntityIds.
   */
  function setAllowedEntityIds(EntityId entityId, bytes32[] memory allowedEntityIds) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((allowedEntityIds)));
  }

  /**
   * @notice Set allowedEntityIds.
   */
  function _setAllowedEntityIds(EntityId entityId, bytes32[] memory allowedEntityIds) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((allowedEntityIds)));
  }

  /**
   * @notice Set allowedEntityIds (using the specified store).
   */
  function setAllowedEntityIds(IStore _store, EntityId entityId, bytes32[] memory allowedEntityIds) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    _store.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((allowedEntityIds)));
  }

  /**
   * @notice Set allowedEntityIds.
   */
  function set(EntityId entityId, bytes32[] memory allowedEntityIds) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((allowedEntityIds)));
  }

  /**
   * @notice Set allowedEntityIds.
   */
  function _set(EntityId entityId, bytes32[] memory allowedEntityIds) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((allowedEntityIds)));
  }

  /**
   * @notice Set allowedEntityIds (using the specified store).
   */
  function set(IStore _store, EntityId entityId, bytes32[] memory allowedEntityIds) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    _store.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((allowedEntityIds)));
  }

  /**
   * @notice Get the length of allowedEntityIds.
   */
  function lengthAllowedEntityIds(EntityId entityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    uint256 _byteLength = StoreSwitch.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 32;
    }
  }

  /**
   * @notice Get the length of allowedEntityIds.
   */
  function _lengthAllowedEntityIds(EntityId entityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    uint256 _byteLength = StoreCore.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 32;
    }
  }

  /**
   * @notice Get the length of allowedEntityIds (using the specified store).
   */
  function lengthAllowedEntityIds(IStore _store, EntityId entityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    uint256 _byteLength = _store.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 32;
    }
  }

  /**
   * @notice Get the length of allowedEntityIds.
   */
  function length(EntityId entityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    uint256 _byteLength = StoreSwitch.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 32;
    }
  }

  /**
   * @notice Get the length of allowedEntityIds.
   */
  function _length(EntityId entityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    uint256 _byteLength = StoreCore.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 32;
    }
  }

  /**
   * @notice Get the length of allowedEntityIds (using the specified store).
   */
  function length(IStore _store, EntityId entityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    uint256 _byteLength = _store.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 32;
    }
  }

  /**
   * @notice Get an item of allowedEntityIds.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItemAllowedEntityIds(EntityId entityId, uint256 _index) internal view returns (bytes32) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _blob = StoreSwitch.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 32, (_index + 1) * 32);
      return (bytes32(_blob));
    }
  }

  /**
   * @notice Get an item of allowedEntityIds.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function _getItemAllowedEntityIds(EntityId entityId, uint256 _index) internal view returns (bytes32) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _blob = StoreCore.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 32, (_index + 1) * 32);
      return (bytes32(_blob));
    }
  }

  /**
   * @notice Get an item of allowedEntityIds (using the specified store).
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItemAllowedEntityIds(IStore _store, EntityId entityId, uint256 _index) internal view returns (bytes32) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _blob = _store.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 32, (_index + 1) * 32);
      return (bytes32(_blob));
    }
  }

  /**
   * @notice Get an item of allowedEntityIds.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItem(EntityId entityId, uint256 _index) internal view returns (bytes32) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _blob = StoreSwitch.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 32, (_index + 1) * 32);
      return (bytes32(_blob));
    }
  }

  /**
   * @notice Get an item of allowedEntityIds.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function _getItem(EntityId entityId, uint256 _index) internal view returns (bytes32) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _blob = StoreCore.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 32, (_index + 1) * 32);
      return (bytes32(_blob));
    }
  }

  /**
   * @notice Get an item of allowedEntityIds (using the specified store).
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItem(IStore _store, EntityId entityId, uint256 _index) internal view returns (bytes32) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _blob = _store.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 32, (_index + 1) * 32);
      return (bytes32(_blob));
    }
  }

  /**
   * @notice Push an element to allowedEntityIds.
   */
  function pushAllowedEntityIds(EntityId entityId, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to allowedEntityIds.
   */
  function _pushAllowedEntityIds(EntityId entityId, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to allowedEntityIds (using the specified store).
   */
  function pushAllowedEntityIds(IStore _store, EntityId entityId, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    _store.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to allowedEntityIds.
   */
  function push(EntityId entityId, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to allowedEntityIds.
   */
  function _push(EntityId entityId, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to allowedEntityIds (using the specified store).
   */
  function push(IStore _store, EntityId entityId, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    _store.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Pop an element from allowedEntityIds.
   */
  function popAllowedEntityIds(EntityId entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.popFromDynamicField(_tableId, _keyTuple, 0, 32);
  }

  /**
   * @notice Pop an element from allowedEntityIds.
   */
  function _popAllowedEntityIds(EntityId entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.popFromDynamicField(_tableId, _keyTuple, 0, 32);
  }

  /**
   * @notice Pop an element from allowedEntityIds (using the specified store).
   */
  function popAllowedEntityIds(IStore _store, EntityId entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    _store.popFromDynamicField(_tableId, _keyTuple, 0, 32);
  }

  /**
   * @notice Pop an element from allowedEntityIds.
   */
  function pop(EntityId entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.popFromDynamicField(_tableId, _keyTuple, 0, 32);
  }

  /**
   * @notice Pop an element from allowedEntityIds.
   */
  function _pop(EntityId entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.popFromDynamicField(_tableId, _keyTuple, 0, 32);
  }

  /**
   * @notice Pop an element from allowedEntityIds (using the specified store).
   */
  function pop(IStore _store, EntityId entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    _store.popFromDynamicField(_tableId, _keyTuple, 0, 32);
  }

  /**
   * @notice Update an element of allowedEntityIds at `_index`.
   */
  function updateAllowedEntityIds(EntityId entityId, uint256 _index, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreSwitch.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 32), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of allowedEntityIds at `_index`.
   */
  function _updateAllowedEntityIds(EntityId entityId, uint256 _index, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreCore.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 32), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of allowedEntityIds (using the specified store) at `_index`.
   */
  function updateAllowedEntityIds(IStore _store, EntityId entityId, uint256 _index, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      _store.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 32), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of allowedEntityIds at `_index`.
   */
  function update(EntityId entityId, uint256 _index, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreSwitch.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 32), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of allowedEntityIds at `_index`.
   */
  function _update(EntityId entityId, uint256 _index, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreCore.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 32), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of allowedEntityIds (using the specified store) at `_index`.
   */
  function update(IStore _store, EntityId entityId, uint256 _index, bytes32 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      _store.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 32), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Delete all data for given keys.
   */
  function deleteRecord(EntityId entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.deleteRecord(_tableId, _keyTuple);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function _deleteRecord(EntityId entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.deleteRecord(_tableId, _keyTuple, _fieldLayout);
  }

  /**
   * @notice Delete all data for given keys (using the specified store).
   */
  function deleteRecord(IStore _store, EntityId entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    _store.deleteRecord(_tableId, _keyTuple);
  }

  /**
   * @notice Tightly pack dynamic data lengths using this table's schema.
   * @return _encodedLengths The lengths of the dynamic fields (packed into a single bytes32 value).
   */
  function encodeLengths(bytes32[] memory allowedEntityIds) internal pure returns (EncodedLengths _encodedLengths) {
    // Lengths are effectively checked during copy by 2**40 bytes exceeding gas limits
    unchecked {
      _encodedLengths = EncodedLengthsLib.pack(allowedEntityIds.length * 32);
    }
  }

  /**
   * @notice Tightly pack dynamic (variable length) data using this table's schema.
   * @return The dynamic data, encoded into a sequence of bytes.
   */
  function encodeDynamic(bytes32[] memory allowedEntityIds) internal pure returns (bytes memory) {
    return abi.encodePacked(EncodeArray.encode((allowedEntityIds)));
  }

  /**
   * @notice Encode all of a record's fields.
   * @return The static (fixed length) data, encoded into a sequence of bytes.
   * @return The lengths of the dynamic fields (packed into a single bytes32 value).
   * @return The dynamic (variable length) data, encoded into a sequence of bytes.
   */
  function encode(
    bytes32[] memory allowedEntityIds
  ) internal pure returns (bytes memory, EncodedLengths, bytes memory) {
    bytes memory _staticData;
    EncodedLengths _encodedLengths = encodeLengths(allowedEntityIds);
    bytes memory _dynamicData = encodeDynamic(allowedEntityIds);

    return (_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Encode keys as a bytes32 array using this table's field layout.
   */
  function encodeKeyTuple(EntityId entityId) internal pure returns (bytes32[] memory) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    return _keyTuple;
  }
}
