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

struct ObjectTypeMetadataData {
  bool isBlock;
  uint16 mass;
  uint8 stackable;
  uint16 damage;
  uint24 durability;
  uint16 hardness;
}

library ObjectTypeMetadata {
  // Hex below is the result of `WorldResourceIdLib.encode({ namespace: "", name: "ObjectTypeMetada", typeId: RESOURCE_TABLE });`
  ResourceId constant _tableId = ResourceId.wrap(0x746200000000000000000000000000004f626a656374547970654d6574616461);

  FieldLayout constant _fieldLayout =
    FieldLayout.wrap(0x000b060001020102030200000000000000000000000000000000000000000000);

  // Hex-encoded key schema of (uint8)
  Schema constant _keySchema = Schema.wrap(0x0001010000000000000000000000000000000000000000000000000000000000);
  // Hex-encoded value schema of (bool, uint16, uint8, uint16, uint24, uint16)
  Schema constant _valueSchema = Schema.wrap(0x000b060060010001020100000000000000000000000000000000000000000000);

  /**
   * @notice Get the table's key field names.
   * @return keyNames An array of strings with the names of key fields.
   */
  function getKeyNames() internal pure returns (string[] memory keyNames) {
    keyNames = new string[](1);
    keyNames[0] = "objectTypeId";
  }

  /**
   * @notice Get the table's value field names.
   * @return fieldNames An array of strings with the names of value fields.
   */
  function getFieldNames() internal pure returns (string[] memory fieldNames) {
    fieldNames = new string[](6);
    fieldNames[0] = "isBlock";
    fieldNames[1] = "mass";
    fieldNames[2] = "stackable";
    fieldNames[3] = "damage";
    fieldNames[4] = "durability";
    fieldNames[5] = "hardness";
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
   * @notice Get isBlock.
   */
  function getIsBlock(uint8 objectTypeId) internal view returns (bool isBlock) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (_toBool(uint8(bytes1(_blob))));
  }

  /**
   * @notice Get isBlock.
   */
  function _getIsBlock(uint8 objectTypeId) internal view returns (bool isBlock) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (_toBool(uint8(bytes1(_blob))));
  }

  /**
   * @notice Get isBlock (using the specified store).
   */
  function getIsBlock(IStore _store, uint8 objectTypeId) internal view returns (bool isBlock) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    bytes32 _blob = _store.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (_toBool(uint8(bytes1(_blob))));
  }

  /**
   * @notice Set isBlock.
   */
  function setIsBlock(uint8 objectTypeId, bool isBlock) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    StoreSwitch.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((isBlock)), _fieldLayout);
  }

  /**
   * @notice Set isBlock.
   */
  function _setIsBlock(uint8 objectTypeId, bool isBlock) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    StoreCore.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((isBlock)), _fieldLayout);
  }

  /**
   * @notice Set isBlock (using the specified store).
   */
  function setIsBlock(IStore _store, uint8 objectTypeId, bool isBlock) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    _store.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((isBlock)), _fieldLayout);
  }

  /**
   * @notice Get mass.
   */
  function getMass(uint8 objectTypeId) internal view returns (uint16 mass) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 1, _fieldLayout);
    return (uint16(bytes2(_blob)));
  }

  /**
   * @notice Get mass.
   */
  function _getMass(uint8 objectTypeId) internal view returns (uint16 mass) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 1, _fieldLayout);
    return (uint16(bytes2(_blob)));
  }

  /**
   * @notice Get mass (using the specified store).
   */
  function getMass(IStore _store, uint8 objectTypeId) internal view returns (uint16 mass) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    bytes32 _blob = _store.getStaticField(_tableId, _keyTuple, 1, _fieldLayout);
    return (uint16(bytes2(_blob)));
  }

  /**
   * @notice Set mass.
   */
  function setMass(uint8 objectTypeId, uint16 mass) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    StoreSwitch.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked((mass)), _fieldLayout);
  }

  /**
   * @notice Set mass.
   */
  function _setMass(uint8 objectTypeId, uint16 mass) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    StoreCore.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked((mass)), _fieldLayout);
  }

  /**
   * @notice Set mass (using the specified store).
   */
  function setMass(IStore _store, uint8 objectTypeId, uint16 mass) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    _store.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked((mass)), _fieldLayout);
  }

  /**
   * @notice Get stackable.
   */
  function getStackable(uint8 objectTypeId) internal view returns (uint8 stackable) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 2, _fieldLayout);
    return (uint8(bytes1(_blob)));
  }

  /**
   * @notice Get stackable.
   */
  function _getStackable(uint8 objectTypeId) internal view returns (uint8 stackable) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 2, _fieldLayout);
    return (uint8(bytes1(_blob)));
  }

  /**
   * @notice Get stackable (using the specified store).
   */
  function getStackable(IStore _store, uint8 objectTypeId) internal view returns (uint8 stackable) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    bytes32 _blob = _store.getStaticField(_tableId, _keyTuple, 2, _fieldLayout);
    return (uint8(bytes1(_blob)));
  }

  /**
   * @notice Set stackable.
   */
  function setStackable(uint8 objectTypeId, uint8 stackable) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    StoreSwitch.setStaticField(_tableId, _keyTuple, 2, abi.encodePacked((stackable)), _fieldLayout);
  }

  /**
   * @notice Set stackable.
   */
  function _setStackable(uint8 objectTypeId, uint8 stackable) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    StoreCore.setStaticField(_tableId, _keyTuple, 2, abi.encodePacked((stackable)), _fieldLayout);
  }

  /**
   * @notice Set stackable (using the specified store).
   */
  function setStackable(IStore _store, uint8 objectTypeId, uint8 stackable) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    _store.setStaticField(_tableId, _keyTuple, 2, abi.encodePacked((stackable)), _fieldLayout);
  }

  /**
   * @notice Get damage.
   */
  function getDamage(uint8 objectTypeId) internal view returns (uint16 damage) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 3, _fieldLayout);
    return (uint16(bytes2(_blob)));
  }

  /**
   * @notice Get damage.
   */
  function _getDamage(uint8 objectTypeId) internal view returns (uint16 damage) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 3, _fieldLayout);
    return (uint16(bytes2(_blob)));
  }

  /**
   * @notice Get damage (using the specified store).
   */
  function getDamage(IStore _store, uint8 objectTypeId) internal view returns (uint16 damage) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    bytes32 _blob = _store.getStaticField(_tableId, _keyTuple, 3, _fieldLayout);
    return (uint16(bytes2(_blob)));
  }

  /**
   * @notice Set damage.
   */
  function setDamage(uint8 objectTypeId, uint16 damage) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    StoreSwitch.setStaticField(_tableId, _keyTuple, 3, abi.encodePacked((damage)), _fieldLayout);
  }

  /**
   * @notice Set damage.
   */
  function _setDamage(uint8 objectTypeId, uint16 damage) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    StoreCore.setStaticField(_tableId, _keyTuple, 3, abi.encodePacked((damage)), _fieldLayout);
  }

  /**
   * @notice Set damage (using the specified store).
   */
  function setDamage(IStore _store, uint8 objectTypeId, uint16 damage) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    _store.setStaticField(_tableId, _keyTuple, 3, abi.encodePacked((damage)), _fieldLayout);
  }

  /**
   * @notice Get durability.
   */
  function getDurability(uint8 objectTypeId) internal view returns (uint24 durability) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 4, _fieldLayout);
    return (uint24(bytes3(_blob)));
  }

  /**
   * @notice Get durability.
   */
  function _getDurability(uint8 objectTypeId) internal view returns (uint24 durability) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 4, _fieldLayout);
    return (uint24(bytes3(_blob)));
  }

  /**
   * @notice Get durability (using the specified store).
   */
  function getDurability(IStore _store, uint8 objectTypeId) internal view returns (uint24 durability) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    bytes32 _blob = _store.getStaticField(_tableId, _keyTuple, 4, _fieldLayout);
    return (uint24(bytes3(_blob)));
  }

  /**
   * @notice Set durability.
   */
  function setDurability(uint8 objectTypeId, uint24 durability) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    StoreSwitch.setStaticField(_tableId, _keyTuple, 4, abi.encodePacked((durability)), _fieldLayout);
  }

  /**
   * @notice Set durability.
   */
  function _setDurability(uint8 objectTypeId, uint24 durability) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    StoreCore.setStaticField(_tableId, _keyTuple, 4, abi.encodePacked((durability)), _fieldLayout);
  }

  /**
   * @notice Set durability (using the specified store).
   */
  function setDurability(IStore _store, uint8 objectTypeId, uint24 durability) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    _store.setStaticField(_tableId, _keyTuple, 4, abi.encodePacked((durability)), _fieldLayout);
  }

  /**
   * @notice Get hardness.
   */
  function getHardness(uint8 objectTypeId) internal view returns (uint16 hardness) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 5, _fieldLayout);
    return (uint16(bytes2(_blob)));
  }

  /**
   * @notice Get hardness.
   */
  function _getHardness(uint8 objectTypeId) internal view returns (uint16 hardness) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 5, _fieldLayout);
    return (uint16(bytes2(_blob)));
  }

  /**
   * @notice Get hardness (using the specified store).
   */
  function getHardness(IStore _store, uint8 objectTypeId) internal view returns (uint16 hardness) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    bytes32 _blob = _store.getStaticField(_tableId, _keyTuple, 5, _fieldLayout);
    return (uint16(bytes2(_blob)));
  }

  /**
   * @notice Set hardness.
   */
  function setHardness(uint8 objectTypeId, uint16 hardness) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    StoreSwitch.setStaticField(_tableId, _keyTuple, 5, abi.encodePacked((hardness)), _fieldLayout);
  }

  /**
   * @notice Set hardness.
   */
  function _setHardness(uint8 objectTypeId, uint16 hardness) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    StoreCore.setStaticField(_tableId, _keyTuple, 5, abi.encodePacked((hardness)), _fieldLayout);
  }

  /**
   * @notice Set hardness (using the specified store).
   */
  function setHardness(IStore _store, uint8 objectTypeId, uint16 hardness) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    _store.setStaticField(_tableId, _keyTuple, 5, abi.encodePacked((hardness)), _fieldLayout);
  }

  /**
   * @notice Get the full data.
   */
  function get(uint8 objectTypeId) internal view returns (ObjectTypeMetadataData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

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
  function _get(uint8 objectTypeId) internal view returns (ObjectTypeMetadataData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    (bytes memory _staticData, EncodedLengths _encodedLengths, bytes memory _dynamicData) = StoreCore.getRecord(
      _tableId,
      _keyTuple,
      _fieldLayout
    );
    return decode(_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Get the full data (using the specified store).
   */
  function get(IStore _store, uint8 objectTypeId) internal view returns (ObjectTypeMetadataData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    (bytes memory _staticData, EncodedLengths _encodedLengths, bytes memory _dynamicData) = _store.getRecord(
      _tableId,
      _keyTuple,
      _fieldLayout
    );
    return decode(_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function set(
    uint8 objectTypeId,
    bool isBlock,
    uint16 mass,
    uint8 stackable,
    uint16 damage,
    uint24 durability,
    uint16 hardness
  ) internal {
    bytes memory _staticData = encodeStatic(isBlock, mass, stackable, damage, durability, hardness);

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function _set(
    uint8 objectTypeId,
    bool isBlock,
    uint16 mass,
    uint8 stackable,
    uint16 damage,
    uint24 durability,
    uint16 hardness
  ) internal {
    bytes memory _staticData = encodeStatic(isBlock, mass, stackable, damage, durability, hardness);

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Set the full data using individual values (using the specified store).
   */
  function set(
    IStore _store,
    uint8 objectTypeId,
    bool isBlock,
    uint16 mass,
    uint8 stackable,
    uint16 damage,
    uint24 durability,
    uint16 hardness
  ) internal {
    bytes memory _staticData = encodeStatic(isBlock, mass, stackable, damage, durability, hardness);

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    _store.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function set(uint8 objectTypeId, ObjectTypeMetadataData memory _table) internal {
    bytes memory _staticData = encodeStatic(
      _table.isBlock,
      _table.mass,
      _table.stackable,
      _table.damage,
      _table.durability,
      _table.hardness
    );

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function _set(uint8 objectTypeId, ObjectTypeMetadataData memory _table) internal {
    bytes memory _staticData = encodeStatic(
      _table.isBlock,
      _table.mass,
      _table.stackable,
      _table.damage,
      _table.durability,
      _table.hardness
    );

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Set the full data using the data struct (using the specified store).
   */
  function set(IStore _store, uint8 objectTypeId, ObjectTypeMetadataData memory _table) internal {
    bytes memory _staticData = encodeStatic(
      _table.isBlock,
      _table.mass,
      _table.stackable,
      _table.damage,
      _table.durability,
      _table.hardness
    );

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    _store.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Decode the tightly packed blob of static data using this table's field layout.
   */
  function decodeStatic(
    bytes memory _blob
  )
    internal
    pure
    returns (bool isBlock, uint16 mass, uint8 stackable, uint16 damage, uint24 durability, uint16 hardness)
  {
    isBlock = (_toBool(uint8(Bytes.getBytes1(_blob, 0))));

    mass = (uint16(Bytes.getBytes2(_blob, 1)));

    stackable = (uint8(Bytes.getBytes1(_blob, 3)));

    damage = (uint16(Bytes.getBytes2(_blob, 4)));

    durability = (uint24(Bytes.getBytes3(_blob, 6)));

    hardness = (uint16(Bytes.getBytes2(_blob, 9)));
  }

  /**
   * @notice Decode the tightly packed blobs using this table's field layout.
   * @param _staticData Tightly packed static fields.
   *
   *
   */
  function decode(
    bytes memory _staticData,
    EncodedLengths,
    bytes memory
  ) internal pure returns (ObjectTypeMetadataData memory _table) {
    (_table.isBlock, _table.mass, _table.stackable, _table.damage, _table.durability, _table.hardness) = decodeStatic(
      _staticData
    );
  }

  /**
   * @notice Delete all data for given keys.
   */
  function deleteRecord(uint8 objectTypeId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    StoreSwitch.deleteRecord(_tableId, _keyTuple);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function _deleteRecord(uint8 objectTypeId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    StoreCore.deleteRecord(_tableId, _keyTuple, _fieldLayout);
  }

  /**
   * @notice Delete all data for given keys (using the specified store).
   */
  function deleteRecord(IStore _store, uint8 objectTypeId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    _store.deleteRecord(_tableId, _keyTuple);
  }

  /**
   * @notice Tightly pack static (fixed length) data using this table's schema.
   * @return The static data, encoded into a sequence of bytes.
   */
  function encodeStatic(
    bool isBlock,
    uint16 mass,
    uint8 stackable,
    uint16 damage,
    uint24 durability,
    uint16 hardness
  ) internal pure returns (bytes memory) {
    return abi.encodePacked(isBlock, mass, stackable, damage, durability, hardness);
  }

  /**
   * @notice Encode all of a record's fields.
   * @return The static (fixed length) data, encoded into a sequence of bytes.
   * @return The lengths of the dynamic fields (packed into a single bytes32 value).
   * @return The dynamic (variable length) data, encoded into a sequence of bytes.
   */
  function encode(
    bool isBlock,
    uint16 mass,
    uint8 stackable,
    uint16 damage,
    uint24 durability,
    uint16 hardness
  ) internal pure returns (bytes memory, EncodedLengths, bytes memory) {
    bytes memory _staticData = encodeStatic(isBlock, mass, stackable, damage, durability, hardness);

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    return (_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Encode keys as a bytes32 array using this table's field layout.
   */
  function encodeKeyTuple(uint8 objectTypeId) internal pure returns (bytes32[] memory) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(objectTypeId));

    return _keyTuple;
  }
}

/**
 * @notice Cast a value to a bool.
 * @dev Boolean values are encoded as uint8 (1 = true, 0 = false), but Solidity doesn't allow casting between uint8 and bool.
 * @param value The uint8 value to convert.
 * @return result The boolean value.
 */
function _toBool(uint8 value) pure returns (bool result) {
  assembly {
    result := value
  }
}