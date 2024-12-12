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
import { ExchangeType } from "./../common.sol";

struct ExchangeChestNotifData {
  address player;
  ExchangeType exchangeType;
  address inToken;
  address inNFT;
  uint8 inObjectTypeId;
  uint256 inAmount;
  address outToken;
  address outNFT;
  uint8 outObjectTypeId;
  uint256 outAmount;
}

library ExchangeChestNotif {
  // Hex below is the result of `WorldResourceIdLib.encode({ namespace: "experience", name: "ExchangeChestNot", typeId: RESOURCE_OFFCHAIN_TABLE });`
  ResourceId constant _tableId = ResourceId.wrap(0x6f74657870657269656e63650000000045786368616e676543686573744e6f74);

  FieldLayout constant _fieldLayout =
    FieldLayout.wrap(0x00a70a0014011414012014140120000000000000000000000000000000000000);

  // Hex-encoded key schema of (bytes32)
  Schema constant _keySchema = Schema.wrap(0x002001005f000000000000000000000000000000000000000000000000000000);
  // Hex-encoded value schema of (address, uint8, address, address, uint8, uint256, address, address, uint8, uint256)
  Schema constant _valueSchema = Schema.wrap(0x00a70a0061006161001f6161001f000000000000000000000000000000000000);

  /**
   * @notice Get the table's key field names.
   * @return keyNames An array of strings with the names of key fields.
   */
  function getKeyNames() internal pure returns (string[] memory keyNames) {
    keyNames = new string[](1);
    keyNames[0] = "chestEntityId";
  }

  /**
   * @notice Get the table's value field names.
   * @return fieldNames An array of strings with the names of value fields.
   */
  function getFieldNames() internal pure returns (string[] memory fieldNames) {
    fieldNames = new string[](10);
    fieldNames[0] = "player";
    fieldNames[1] = "exchangeType";
    fieldNames[2] = "inToken";
    fieldNames[3] = "inNFT";
    fieldNames[4] = "inObjectTypeId";
    fieldNames[5] = "inAmount";
    fieldNames[6] = "outToken";
    fieldNames[7] = "outNFT";
    fieldNames[8] = "outObjectTypeId";
    fieldNames[9] = "outAmount";
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
  function setPlayer(bytes32 chestEntityId, address player) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((player)), _fieldLayout);
  }

  /**
   * @notice Set player.
   */
  function _setPlayer(bytes32 chestEntityId, address player) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreCore.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((player)), _fieldLayout);
  }

  /**
   * @notice Set player (using the specified store).
   */
  function setPlayer(IStore _store, bytes32 chestEntityId, address player) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    _store.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((player)), _fieldLayout);
  }

  /**
   * @notice Set exchangeType.
   */
  function setExchangeType(bytes32 chestEntityId, ExchangeType exchangeType) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked(uint8(exchangeType)), _fieldLayout);
  }

  /**
   * @notice Set exchangeType.
   */
  function _setExchangeType(bytes32 chestEntityId, ExchangeType exchangeType) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreCore.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked(uint8(exchangeType)), _fieldLayout);
  }

  /**
   * @notice Set exchangeType (using the specified store).
   */
  function setExchangeType(IStore _store, bytes32 chestEntityId, ExchangeType exchangeType) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    _store.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked(uint8(exchangeType)), _fieldLayout);
  }

  /**
   * @notice Set inToken.
   */
  function setInToken(bytes32 chestEntityId, address inToken) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 2, abi.encodePacked((inToken)), _fieldLayout);
  }

  /**
   * @notice Set inToken.
   */
  function _setInToken(bytes32 chestEntityId, address inToken) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreCore.setStaticField(_tableId, _keyTuple, 2, abi.encodePacked((inToken)), _fieldLayout);
  }

  /**
   * @notice Set inToken (using the specified store).
   */
  function setInToken(IStore _store, bytes32 chestEntityId, address inToken) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    _store.setStaticField(_tableId, _keyTuple, 2, abi.encodePacked((inToken)), _fieldLayout);
  }

  /**
   * @notice Set inNFT.
   */
  function setInNFT(bytes32 chestEntityId, address inNFT) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 3, abi.encodePacked((inNFT)), _fieldLayout);
  }

  /**
   * @notice Set inNFT.
   */
  function _setInNFT(bytes32 chestEntityId, address inNFT) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreCore.setStaticField(_tableId, _keyTuple, 3, abi.encodePacked((inNFT)), _fieldLayout);
  }

  /**
   * @notice Set inNFT (using the specified store).
   */
  function setInNFT(IStore _store, bytes32 chestEntityId, address inNFT) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    _store.setStaticField(_tableId, _keyTuple, 3, abi.encodePacked((inNFT)), _fieldLayout);
  }

  /**
   * @notice Set inObjectTypeId.
   */
  function setInObjectTypeId(bytes32 chestEntityId, uint8 inObjectTypeId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 4, abi.encodePacked((inObjectTypeId)), _fieldLayout);
  }

  /**
   * @notice Set inObjectTypeId.
   */
  function _setInObjectTypeId(bytes32 chestEntityId, uint8 inObjectTypeId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreCore.setStaticField(_tableId, _keyTuple, 4, abi.encodePacked((inObjectTypeId)), _fieldLayout);
  }

  /**
   * @notice Set inObjectTypeId (using the specified store).
   */
  function setInObjectTypeId(IStore _store, bytes32 chestEntityId, uint8 inObjectTypeId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    _store.setStaticField(_tableId, _keyTuple, 4, abi.encodePacked((inObjectTypeId)), _fieldLayout);
  }

  /**
   * @notice Set inAmount.
   */
  function setInAmount(bytes32 chestEntityId, uint256 inAmount) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 5, abi.encodePacked((inAmount)), _fieldLayout);
  }

  /**
   * @notice Set inAmount.
   */
  function _setInAmount(bytes32 chestEntityId, uint256 inAmount) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreCore.setStaticField(_tableId, _keyTuple, 5, abi.encodePacked((inAmount)), _fieldLayout);
  }

  /**
   * @notice Set inAmount (using the specified store).
   */
  function setInAmount(IStore _store, bytes32 chestEntityId, uint256 inAmount) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    _store.setStaticField(_tableId, _keyTuple, 5, abi.encodePacked((inAmount)), _fieldLayout);
  }

  /**
   * @notice Set outToken.
   */
  function setOutToken(bytes32 chestEntityId, address outToken) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 6, abi.encodePacked((outToken)), _fieldLayout);
  }

  /**
   * @notice Set outToken.
   */
  function _setOutToken(bytes32 chestEntityId, address outToken) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreCore.setStaticField(_tableId, _keyTuple, 6, abi.encodePacked((outToken)), _fieldLayout);
  }

  /**
   * @notice Set outToken (using the specified store).
   */
  function setOutToken(IStore _store, bytes32 chestEntityId, address outToken) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    _store.setStaticField(_tableId, _keyTuple, 6, abi.encodePacked((outToken)), _fieldLayout);
  }

  /**
   * @notice Set outNFT.
   */
  function setOutNFT(bytes32 chestEntityId, address outNFT) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 7, abi.encodePacked((outNFT)), _fieldLayout);
  }

  /**
   * @notice Set outNFT.
   */
  function _setOutNFT(bytes32 chestEntityId, address outNFT) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreCore.setStaticField(_tableId, _keyTuple, 7, abi.encodePacked((outNFT)), _fieldLayout);
  }

  /**
   * @notice Set outNFT (using the specified store).
   */
  function setOutNFT(IStore _store, bytes32 chestEntityId, address outNFT) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    _store.setStaticField(_tableId, _keyTuple, 7, abi.encodePacked((outNFT)), _fieldLayout);
  }

  /**
   * @notice Set outObjectTypeId.
   */
  function setOutObjectTypeId(bytes32 chestEntityId, uint8 outObjectTypeId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 8, abi.encodePacked((outObjectTypeId)), _fieldLayout);
  }

  /**
   * @notice Set outObjectTypeId.
   */
  function _setOutObjectTypeId(bytes32 chestEntityId, uint8 outObjectTypeId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreCore.setStaticField(_tableId, _keyTuple, 8, abi.encodePacked((outObjectTypeId)), _fieldLayout);
  }

  /**
   * @notice Set outObjectTypeId (using the specified store).
   */
  function setOutObjectTypeId(IStore _store, bytes32 chestEntityId, uint8 outObjectTypeId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    _store.setStaticField(_tableId, _keyTuple, 8, abi.encodePacked((outObjectTypeId)), _fieldLayout);
  }

  /**
   * @notice Set outAmount.
   */
  function setOutAmount(bytes32 chestEntityId, uint256 outAmount) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 9, abi.encodePacked((outAmount)), _fieldLayout);
  }

  /**
   * @notice Set outAmount.
   */
  function _setOutAmount(bytes32 chestEntityId, uint256 outAmount) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreCore.setStaticField(_tableId, _keyTuple, 9, abi.encodePacked((outAmount)), _fieldLayout);
  }

  /**
   * @notice Set outAmount (using the specified store).
   */
  function setOutAmount(IStore _store, bytes32 chestEntityId, uint256 outAmount) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    _store.setStaticField(_tableId, _keyTuple, 9, abi.encodePacked((outAmount)), _fieldLayout);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function set(
    bytes32 chestEntityId,
    address player,
    ExchangeType exchangeType,
    address inToken,
    address inNFT,
    uint8 inObjectTypeId,
    uint256 inAmount,
    address outToken,
    address outNFT,
    uint8 outObjectTypeId,
    uint256 outAmount
  ) internal {
    bytes memory _staticData = encodeStatic(
      player,
      exchangeType,
      inToken,
      inNFT,
      inObjectTypeId,
      inAmount,
      outToken,
      outNFT,
      outObjectTypeId,
      outAmount
    );

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function _set(
    bytes32 chestEntityId,
    address player,
    ExchangeType exchangeType,
    address inToken,
    address inNFT,
    uint8 inObjectTypeId,
    uint256 inAmount,
    address outToken,
    address outNFT,
    uint8 outObjectTypeId,
    uint256 outAmount
  ) internal {
    bytes memory _staticData = encodeStatic(
      player,
      exchangeType,
      inToken,
      inNFT,
      inObjectTypeId,
      inAmount,
      outToken,
      outNFT,
      outObjectTypeId,
      outAmount
    );

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Set the full data using individual values (using the specified store).
   */
  function set(
    IStore _store,
    bytes32 chestEntityId,
    address player,
    ExchangeType exchangeType,
    address inToken,
    address inNFT,
    uint8 inObjectTypeId,
    uint256 inAmount,
    address outToken,
    address outNFT,
    uint8 outObjectTypeId,
    uint256 outAmount
  ) internal {
    bytes memory _staticData = encodeStatic(
      player,
      exchangeType,
      inToken,
      inNFT,
      inObjectTypeId,
      inAmount,
      outToken,
      outNFT,
      outObjectTypeId,
      outAmount
    );

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    _store.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function set(bytes32 chestEntityId, ExchangeChestNotifData memory _table) internal {
    bytes memory _staticData = encodeStatic(
      _table.player,
      _table.exchangeType,
      _table.inToken,
      _table.inNFT,
      _table.inObjectTypeId,
      _table.inAmount,
      _table.outToken,
      _table.outNFT,
      _table.outObjectTypeId,
      _table.outAmount
    );

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function _set(bytes32 chestEntityId, ExchangeChestNotifData memory _table) internal {
    bytes memory _staticData = encodeStatic(
      _table.player,
      _table.exchangeType,
      _table.inToken,
      _table.inNFT,
      _table.inObjectTypeId,
      _table.inAmount,
      _table.outToken,
      _table.outNFT,
      _table.outObjectTypeId,
      _table.outAmount
    );

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Set the full data using the data struct (using the specified store).
   */
  function set(IStore _store, bytes32 chestEntityId, ExchangeChestNotifData memory _table) internal {
    bytes memory _staticData = encodeStatic(
      _table.player,
      _table.exchangeType,
      _table.inToken,
      _table.inNFT,
      _table.inObjectTypeId,
      _table.inAmount,
      _table.outToken,
      _table.outNFT,
      _table.outObjectTypeId,
      _table.outAmount
    );

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

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
      ExchangeType exchangeType,
      address inToken,
      address inNFT,
      uint8 inObjectTypeId,
      uint256 inAmount,
      address outToken,
      address outNFT,
      uint8 outObjectTypeId,
      uint256 outAmount
    )
  {
    player = (address(Bytes.getBytes20(_blob, 0)));

    exchangeType = ExchangeType(uint8(Bytes.getBytes1(_blob, 20)));

    inToken = (address(Bytes.getBytes20(_blob, 21)));

    inNFT = (address(Bytes.getBytes20(_blob, 41)));

    inObjectTypeId = (uint8(Bytes.getBytes1(_blob, 61)));

    inAmount = (uint256(Bytes.getBytes32(_blob, 62)));

    outToken = (address(Bytes.getBytes20(_blob, 94)));

    outNFT = (address(Bytes.getBytes20(_blob, 114)));

    outObjectTypeId = (uint8(Bytes.getBytes1(_blob, 134)));

    outAmount = (uint256(Bytes.getBytes32(_blob, 135)));
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
  ) internal pure returns (ExchangeChestNotifData memory _table) {
    (
      _table.player,
      _table.exchangeType,
      _table.inToken,
      _table.inNFT,
      _table.inObjectTypeId,
      _table.inAmount,
      _table.outToken,
      _table.outNFT,
      _table.outObjectTypeId,
      _table.outAmount
    ) = decodeStatic(_staticData);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function deleteRecord(bytes32 chestEntityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.deleteRecord(_tableId, _keyTuple);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function _deleteRecord(bytes32 chestEntityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreCore.deleteRecord(_tableId, _keyTuple, _fieldLayout);
  }

  /**
   * @notice Delete all data for given keys (using the specified store).
   */
  function deleteRecord(IStore _store, bytes32 chestEntityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    _store.deleteRecord(_tableId, _keyTuple);
  }

  /**
   * @notice Tightly pack static (fixed length) data using this table's schema.
   * @return The static data, encoded into a sequence of bytes.
   */
  function encodeStatic(
    address player,
    ExchangeType exchangeType,
    address inToken,
    address inNFT,
    uint8 inObjectTypeId,
    uint256 inAmount,
    address outToken,
    address outNFT,
    uint8 outObjectTypeId,
    uint256 outAmount
  ) internal pure returns (bytes memory) {
    return
      abi.encodePacked(
        player,
        exchangeType,
        inToken,
        inNFT,
        inObjectTypeId,
        inAmount,
        outToken,
        outNFT,
        outObjectTypeId,
        outAmount
      );
  }

  /**
   * @notice Encode all of a record's fields.
   * @return The static (fixed length) data, encoded into a sequence of bytes.
   * @return The lengths of the dynamic fields (packed into a single bytes32 value).
   * @return The dynamic (variable length) data, encoded into a sequence of bytes.
   */
  function encode(
    address player,
    ExchangeType exchangeType,
    address inToken,
    address inNFT,
    uint8 inObjectTypeId,
    uint256 inAmount,
    address outToken,
    address outNFT,
    uint8 outObjectTypeId,
    uint256 outAmount
  ) internal pure returns (bytes memory, EncodedLengths, bytes memory) {
    bytes memory _staticData = encodeStatic(
      player,
      exchangeType,
      inToken,
      inNFT,
      inObjectTypeId,
      inAmount,
      outToken,
      outNFT,
      outObjectTypeId,
      outAmount
    );

    EncodedLengths _encodedLengths;
    bytes memory _dynamicData;

    return (_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Encode keys as a bytes32 array using this table's field layout.
   */
  function encodeKeyTuple(bytes32 chestEntityId) internal pure returns (bytes32[] memory) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    return _keyTuple;
  }
}
