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
import { ResourceType } from "../common.sol";

struct ExchangeNotifData {
  address player;
  ResourceType inResourceType;
  bytes32 inResourceId;
  uint256 inAmount;
  ResourceType outResourceType;
  bytes32 outResourceId;
  uint256 outAmount;
}

library ExchangeNotif {
  // Hex below is the result of `WorldResourceIdLib.encode({ namespace: "experience", name: "ExchangeNotif", typeId: RESOURCE_OFFCHAIN_TABLE });`
  ResourceId constant _tableId = ResourceId.wrap(0x6f74657870657269656e63650000000045786368616e67654e6f746966000000);

  FieldLayout constant _fieldLayout =
    FieldLayout.wrap(0x0096070014012020012020000000000000000000000000000000000000000000);

  // Hex-encoded key schema of (bytes32)
  Schema constant _keySchema = Schema.wrap(0x002001005f000000000000000000000000000000000000000000000000000000);
  // Hex-encoded value schema of (address, uint8, bytes32, uint256, uint8, bytes32, uint256)
  Schema constant _valueSchema = Schema.wrap(0x0096070061005f1f005f1f000000000000000000000000000000000000000000);

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
    fieldNames = new string[](7);
    fieldNames[0] = "player";
    fieldNames[1] = "inResourceType";
    fieldNames[2] = "inResourceId";
    fieldNames[3] = "inAmount";
    fieldNames[4] = "outResourceType";
    fieldNames[5] = "outResourceId";
    fieldNames[6] = "outAmount";
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
   * @notice Set player.
   */
  function setPlayer(EntityId entityId, address player) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((player)), _fieldLayout);
  }

  /**
   * @notice Set player.
   */
  function _setPlayer(EntityId entityId, address player) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((player)), _fieldLayout);
  }

  /**
   * @notice Set player (using the specified store).
   */
  function setPlayer(IStore _store, EntityId entityId, address player) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    _store.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((player)), _fieldLayout);
  }

  /**
   * @notice Set inResourceType.
   */
  function setInResourceType(EntityId entityId, ResourceType inResourceType) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked(uint8(inResourceType)), _fieldLayout);
  }

  /**
   * @notice Set inResourceType.
   */
  function _setInResourceType(EntityId entityId, ResourceType inResourceType) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked(uint8(inResourceType)), _fieldLayout);
  }

  /**
   * @notice Set inResourceType (using the specified store).
   */
  function setInResourceType(IStore _store, EntityId entityId, ResourceType inResourceType) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    _store.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked(uint8(inResourceType)), _fieldLayout);
  }

  /**
   * @notice Set inResourceId.
   */
  function setInResourceId(EntityId entityId, bytes32 inResourceId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.setStaticField(_tableId, _keyTuple, 2, abi.encodePacked((inResourceId)), _fieldLayout);
  }

  /**
   * @notice Set inResourceId.
   */
  function _setInResourceId(EntityId entityId, bytes32 inResourceId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.setStaticField(_tableId, _keyTuple, 2, abi.encodePacked((inResourceId)), _fieldLayout);
  }

  /**
   * @notice Set inResourceId (using the specified store).
   */
  function setInResourceId(IStore _store, EntityId entityId, bytes32 inResourceId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    _store.setStaticField(_tableId, _keyTuple, 2, abi.encodePacked((inResourceId)), _fieldLayout);
  }

  /**
   * @notice Set inAmount.
   */
  function setInAmount(EntityId entityId, uint256 inAmount) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.setStaticField(_tableId, _keyTuple, 3, abi.encodePacked((inAmount)), _fieldLayout);
  }

  /**
   * @notice Set inAmount.
   */
  function _setInAmount(EntityId entityId, uint256 inAmount) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.setStaticField(_tableId, _keyTuple, 3, abi.encodePacked((inAmount)), _fieldLayout);
  }

  /**
   * @notice Set inAmount (using the specified store).
   */
  function setInAmount(IStore _store, EntityId entityId, uint256 inAmount) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    _store.setStaticField(_tableId, _keyTuple, 3, abi.encodePacked((inAmount)), _fieldLayout);
  }

  /**
   * @notice Set outResourceType.
   */
  function setOutResourceType(EntityId entityId, ResourceType outResourceType) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.setStaticField(_tableId, _keyTuple, 4, abi.encodePacked(uint8(outResourceType)), _fieldLayout);
  }

  /**
   * @notice Set outResourceType.
   */
  function _setOutResourceType(EntityId entityId, ResourceType outResourceType) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.setStaticField(_tableId, _keyTuple, 4, abi.encodePacked(uint8(outResourceType)), _fieldLayout);
  }

  /**
   * @notice Set outResourceType (using the specified store).
   */
  function setOutResourceType(IStore _store, EntityId entityId, ResourceType outResourceType) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    _store.setStaticField(_tableId, _keyTuple, 4, abi.encodePacked(uint8(outResourceType)), _fieldLayout);
  }

  /**
   * @notice Set outResourceId.
   */
  function setOutResourceId(EntityId entityId, bytes32 outResourceId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.setStaticField(_tableId, _keyTuple, 5, abi.encodePacked((outResourceId)), _fieldLayout);
  }

  /**
   * @notice Set outResourceId.
   */
  function _setOutResourceId(EntityId entityId, bytes32 outResourceId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.setStaticField(_tableId, _keyTuple, 5, abi.encodePacked((outResourceId)), _fieldLayout);
  }

  /**
   * @notice Set outResourceId (using the specified store).
   */
  function setOutResourceId(IStore _store, EntityId entityId, bytes32 outResourceId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    _store.setStaticField(_tableId, _keyTuple, 5, abi.encodePacked((outResourceId)), _fieldLayout);
  }

  /**
   * @notice Set outAmount.
   */
  function setOutAmount(EntityId entityId, uint256 outAmount) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.setStaticField(_tableId, _keyTuple, 6, abi.encodePacked((outAmount)), _fieldLayout);
  }

  /**
   * @notice Set outAmount.
   */
  function _setOutAmount(EntityId entityId, uint256 outAmount) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.setStaticField(_tableId, _keyTuple, 6, abi.encodePacked((outAmount)), _fieldLayout);
  }

  /**
   * @notice Set outAmount (using the specified store).
   */
  function setOutAmount(IStore _store, EntityId entityId, uint256 outAmount) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    _store.setStaticField(_tableId, _keyTuple, 6, abi.encodePacked((outAmount)), _fieldLayout);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function set(
    EntityId entityId,
    address player,
    ResourceType inResourceType,
    bytes32 inResourceId,
    uint256 inAmount,
    ResourceType outResourceType,
    bytes32 outResourceId,
    uint256 outAmount
  ) internal {
    bytes memory _staticData = encodeStatic(
      player,
      inResourceType,
      inResourceId,
      inAmount,
      outResourceType,
      outResourceId,
      outAmount
    );

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function _set(
    EntityId entityId,
    address player,
    ResourceType inResourceType,
    bytes32 inResourceId,
    uint256 inAmount,
    ResourceType outResourceType,
    bytes32 outResourceId,
    uint256 outAmount
  ) internal {
    bytes memory _staticData = encodeStatic(
      player,
      inResourceType,
      inResourceId,
      inAmount,
      outResourceType,
      outResourceId,
      outAmount
    );

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Set the full data using individual values (using the specified store).
   */
  function set(
    IStore _store,
    EntityId entityId,
    address player,
    ResourceType inResourceType,
    bytes32 inResourceId,
    uint256 inAmount,
    ResourceType outResourceType,
    bytes32 outResourceId,
    uint256 outAmount
  ) internal {
    bytes memory _staticData = encodeStatic(
      player,
      inResourceType,
      inResourceId,
      inAmount,
      outResourceType,
      outResourceId,
      outAmount
    );

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    _store.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function set(EntityId entityId, ExchangeNotifData memory _table) internal {
    bytes memory _staticData = encodeStatic(
      _table.player,
      _table.inResourceType,
      _table.inResourceId,
      _table.inAmount,
      _table.outResourceType,
      _table.outResourceId,
      _table.outAmount
    );

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function _set(EntityId entityId, ExchangeNotifData memory _table) internal {
    bytes memory _staticData = encodeStatic(
      _table.player,
      _table.inResourceType,
      _table.inResourceId,
      _table.inAmount,
      _table.outResourceType,
      _table.outResourceId,
      _table.outAmount
    );

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Set the full data using the data struct (using the specified store).
   */
  function set(IStore _store, EntityId entityId, ExchangeNotifData memory _table) internal {
    bytes memory _staticData = encodeStatic(
      _table.player,
      _table.inResourceType,
      _table.inResourceId,
      _table.inAmount,
      _table.outResourceType,
      _table.outResourceId,
      _table.outAmount
    );

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

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
    returns (
      address player,
      ResourceType inResourceType,
      bytes32 inResourceId,
      uint256 inAmount,
      ResourceType outResourceType,
      bytes32 outResourceId,
      uint256 outAmount
    )
  {
    player = (address(Bytes.getBytes20(_blob, 0)));

    inResourceType = ResourceType(uint8(Bytes.getBytes1(_blob, 20)));

    inResourceId = (Bytes.getBytes32(_blob, 21));

    inAmount = (uint256(Bytes.getBytes32(_blob, 53)));

    outResourceType = ResourceType(uint8(Bytes.getBytes1(_blob, 85)));

    outResourceId = (Bytes.getBytes32(_blob, 86));

    outAmount = (uint256(Bytes.getBytes32(_blob, 118)));
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
  ) internal pure returns (ExchangeNotifData memory _table) {
    (
      _table.player,
      _table.inResourceType,
      _table.inResourceId,
      _table.inAmount,
      _table.outResourceType,
      _table.outResourceId,
      _table.outAmount
    ) = decodeStatic(_staticData);
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
   * @notice Tightly pack static (fixed length) data using this table's schema.
   * @return The static data, encoded into a sequence of bytes.
   */
  function encodeStatic(
    address player,
    ResourceType inResourceType,
    bytes32 inResourceId,
    uint256 inAmount,
    ResourceType outResourceType,
    bytes32 outResourceId,
    uint256 outAmount
  ) internal pure returns (bytes memory) {
    return abi.encodePacked(player, inResourceType, inResourceId, inAmount, outResourceType, outResourceId, outAmount);
  }

  /**
   * @notice Encode all of a record's fields.
   * @return The static (fixed length) data, encoded into a sequence of bytes.
   * @return The lengths of the dynamic fields (packed into a single bytes32 value).
   * @return The dynamic (variable length) data, encoded into a sequence of bytes.
   */
  function encode(
    address player,
    ResourceType inResourceType,
    bytes32 inResourceId,
    uint256 inAmount,
    ResourceType outResourceType,
    bytes32 outResourceId,
    uint256 outAmount
  ) internal pure returns (bytes memory, EncodedLengths, bytes memory) {
    bytes memory _staticData = encodeStatic(
      player,
      inResourceType,
      inResourceId,
      inAmount,
      outResourceType,
      outResourceId,
      outAmount
    );

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

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
