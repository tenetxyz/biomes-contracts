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
import { DisplayContentType } from "../common.sol";

struct DisplayContentData {
  DisplayContentType contentType;
  bytes content;
}

library DisplayContent {
  // Hex below is the result of `WorldResourceIdLib.encode({ namespace: "", name: "DisplayContent", typeId: RESOURCE_TABLE });`
  ResourceId constant _tableId = ResourceId.wrap(0x74620000000000000000000000000000446973706c6179436f6e74656e740000);

  FieldLayout constant _fieldLayout =
    FieldLayout.wrap(0x0001010101000000000000000000000000000000000000000000000000000000);

  // Hex-encoded key schema of (bytes32)
  Schema constant _keySchema = Schema.wrap(0x002001005f000000000000000000000000000000000000000000000000000000);
  // Hex-encoded value schema of (uint8, bytes)
  Schema constant _valueSchema = Schema.wrap(0x0001010100c40000000000000000000000000000000000000000000000000000);

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
    fieldNames = new string[](2);
    fieldNames[0] = "contentType";
    fieldNames[1] = "content";
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
   * @notice Get contentType.
   */
  function getContentType(EntityId entityId) internal view returns (DisplayContentType contentType) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return DisplayContentType(uint8(bytes1(_blob)));
  }

  /**
   * @notice Get contentType.
   */
  function _getContentType(EntityId entityId) internal view returns (DisplayContentType contentType) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return DisplayContentType(uint8(bytes1(_blob)));
  }

  /**
   * @notice Set contentType.
   */
  function setContentType(EntityId entityId, DisplayContentType contentType) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked(uint8(contentType)), _fieldLayout);
  }

  /**
   * @notice Set contentType.
   */
  function _setContentType(EntityId entityId, DisplayContentType contentType) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked(uint8(contentType)), _fieldLayout);
  }

  /**
   * @notice Get content.
   */
  function getContent(EntityId entityId) internal view returns (bytes memory content) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    bytes memory _blob = StoreSwitch.getDynamicField(_tableId, _keyTuple, 0);
    return (bytes(_blob));
  }

  /**
   * @notice Get content.
   */
  function _getContent(EntityId entityId) internal view returns (bytes memory content) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    bytes memory _blob = StoreCore.getDynamicField(_tableId, _keyTuple, 0);
    return (bytes(_blob));
  }

  /**
   * @notice Set content.
   */
  function setContent(EntityId entityId, bytes memory content) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.setDynamicField(_tableId, _keyTuple, 0, bytes((content)));
  }

  /**
   * @notice Set content.
   */
  function _setContent(EntityId entityId, bytes memory content) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.setDynamicField(_tableId, _keyTuple, 0, bytes((content)));
  }

  /**
   * @notice Get the length of content.
   */
  function lengthContent(EntityId entityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    uint256 _byteLength = StoreSwitch.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 1;
    }
  }

  /**
   * @notice Get the length of content.
   */
  function _lengthContent(EntityId entityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    uint256 _byteLength = StoreCore.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 1;
    }
  }

  /**
   * @notice Get an item of content.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItemContent(EntityId entityId, uint256 _index) internal view returns (bytes memory) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _blob = StoreSwitch.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 1, (_index + 1) * 1);
      return (bytes(_blob));
    }
  }

  /**
   * @notice Get an item of content.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function _getItemContent(EntityId entityId, uint256 _index) internal view returns (bytes memory) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _blob = StoreCore.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 1, (_index + 1) * 1);
      return (bytes(_blob));
    }
  }

  /**
   * @notice Push a slice to content.
   */
  function pushContent(EntityId entityId, bytes memory _slice) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.pushToDynamicField(_tableId, _keyTuple, 0, bytes((_slice)));
  }

  /**
   * @notice Push a slice to content.
   */
  function _pushContent(EntityId entityId, bytes memory _slice) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.pushToDynamicField(_tableId, _keyTuple, 0, bytes((_slice)));
  }

  /**
   * @notice Pop a slice from content.
   */
  function popContent(EntityId entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.popFromDynamicField(_tableId, _keyTuple, 0, 1);
  }

  /**
   * @notice Pop a slice from content.
   */
  function _popContent(EntityId entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.popFromDynamicField(_tableId, _keyTuple, 0, 1);
  }

  /**
   * @notice Update a slice of content at `_index`.
   */
  function updateContent(EntityId entityId, uint256 _index, bytes memory _slice) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _encoded = bytes((_slice));
      StoreSwitch.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 1), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update a slice of content at `_index`.
   */
  function _updateContent(EntityId entityId, uint256 _index, bytes memory _slice) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _encoded = bytes((_slice));
      StoreCore.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 1), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Get the full data.
   */
  function get(EntityId entityId) internal view returns (DisplayContentData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    (bytes memory _staticData, EncodedLengths _encodedLengths, bytes memory _dynamicData) = StoreSwitch.getRecord(
      _tableId,
      _keyTuple,
      _fieldLayout
    );
    return decode(_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Get the full data.
   */
  function _get(EntityId entityId) internal view returns (DisplayContentData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    (bytes memory _staticData, EncodedLengths _encodedLengths, bytes memory _dynamicData) = StoreCore.getRecord(
      _tableId,
      _keyTuple,
      _fieldLayout
    );
    return decode(_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function set(EntityId entityId, DisplayContentType contentType, bytes memory content) internal {
    bytes memory _staticData = encodeStatic(contentType);

    EncodedLengths _encodedLengths = encodeLengths(content);
    bytes memory _dynamicData = encodeDynamic(content);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function _set(EntityId entityId, DisplayContentType contentType, bytes memory content) internal {
    bytes memory _staticData = encodeStatic(contentType);

    EncodedLengths _encodedLengths = encodeLengths(content);
    bytes memory _dynamicData = encodeDynamic(content);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function set(EntityId entityId, DisplayContentData memory _table) internal {
    bytes memory _staticData = encodeStatic(_table.contentType);

    EncodedLengths _encodedLengths = encodeLengths(_table.content);
    bytes memory _dynamicData = encodeDynamic(_table.content);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function _set(EntityId entityId, DisplayContentData memory _table) internal {
    bytes memory _staticData = encodeStatic(_table.contentType);

    EncodedLengths _encodedLengths = encodeLengths(_table.content);
    bytes memory _dynamicData = encodeDynamic(_table.content);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Decode the tightly packed blob of static data using this table's field layout.
   */
  function decodeStatic(bytes memory _blob) internal pure returns (DisplayContentType contentType) {
    contentType = DisplayContentType(uint8(Bytes.getBytes1(_blob, 0)));
  }

  /**
   * @notice Decode the tightly packed blob of dynamic data using the encoded lengths.
   */
  function decodeDynamic(
    EncodedLengths _encodedLengths,
    bytes memory _blob
  ) internal pure returns (bytes memory content) {
    uint256 _start;
    uint256 _end;
    unchecked {
      _end = _encodedLengths.atIndex(0);
    }
    content = (bytes(SliceLib.getSubslice(_blob, _start, _end).toBytes()));
  }

  /**
   * @notice Decode the tightly packed blobs using this table's field layout.
   * @param _staticData Tightly packed static fields.
   * @param _encodedLengths Encoded lengths of dynamic fields.
   * @param _dynamicData Tightly packed dynamic fields.
   */
  function decode(
    bytes memory _staticData,
    EncodedLengths _encodedLengths,
    bytes memory _dynamicData
  ) internal pure returns (DisplayContentData memory _table) {
    (_table.contentType) = decodeStatic(_staticData);

    (_table.content) = decodeDynamic(_encodedLengths, _dynamicData);
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
   * @notice Tightly pack static (fixed length) data using this table's schema.
   * @return The static data, encoded into a sequence of bytes.
   */
  function encodeStatic(DisplayContentType contentType) internal pure returns (bytes memory) {
    return abi.encodePacked(contentType);
  }

  /**
   * @notice Tightly pack dynamic data lengths using this table's schema.
   * @return _encodedLengths The lengths of the dynamic fields (packed into a single bytes32 value).
   */
  function encodeLengths(bytes memory content) internal pure returns (EncodedLengths _encodedLengths) {
    // Lengths are effectively checked during copy by 2**40 bytes exceeding gas limits
    unchecked {
      _encodedLengths = EncodedLengthsLib.pack(bytes(content).length);
    }
  }

  /**
   * @notice Tightly pack dynamic (variable length) data using this table's schema.
   * @return The dynamic data, encoded into a sequence of bytes.
   */
  function encodeDynamic(bytes memory content) internal pure returns (bytes memory) {
    return abi.encodePacked(bytes((content)));
  }

  /**
   * @notice Encode all of a record's fields.
   * @return The static (fixed length) data, encoded into a sequence of bytes.
   * @return The lengths of the dynamic fields (packed into a single bytes32 value).
   * @return The dynamic (variable length) data, encoded into a sequence of bytes.
   */
  function encode(
    DisplayContentType contentType,
    bytes memory content
  ) internal pure returns (bytes memory, EncodedLengths, bytes memory) {
    bytes memory _staticData = encodeStatic(contentType);

    EncodedLengths _encodedLengths = encodeLengths(content);
    bytes memory _dynamicData = encodeDynamic(content);

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
