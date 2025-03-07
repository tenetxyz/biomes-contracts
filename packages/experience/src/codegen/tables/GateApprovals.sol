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

struct GateApprovalsData {
  address[] players;
  address[] nfts;
}

library GateApprovals {
  // Hex below is the result of `WorldResourceIdLib.encode({ namespace: "experience", name: "GateApprovals", typeId: RESOURCE_TABLE });`
  ResourceId constant _tableId = ResourceId.wrap(0x7462657870657269656e63650000000047617465417070726f76616c73000000);

  FieldLayout constant _fieldLayout =
    FieldLayout.wrap(0x0000000200000000000000000000000000000000000000000000000000000000);

  // Hex-encoded key schema of (bytes32)
  Schema constant _keySchema = Schema.wrap(0x002001005f000000000000000000000000000000000000000000000000000000);
  // Hex-encoded value schema of (address[], address[])
  Schema constant _valueSchema = Schema.wrap(0x00000002c3c30000000000000000000000000000000000000000000000000000);

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
    fieldNames[0] = "players";
    fieldNames[1] = "nfts";
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
   * @notice Get players.
   */
  function getPlayers(EntityId entityId) internal view returns (address[] memory players) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    bytes memory _blob = StoreSwitch.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_address());
  }

  /**
   * @notice Get players.
   */
  function _getPlayers(EntityId entityId) internal view returns (address[] memory players) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    bytes memory _blob = StoreCore.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_address());
  }

  /**
   * @notice Get players (using the specified store).
   */
  function getPlayers(IStore _store, EntityId entityId) internal view returns (address[] memory players) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    bytes memory _blob = _store.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_address());
  }

  /**
   * @notice Set players.
   */
  function setPlayers(EntityId entityId, address[] memory players) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((players)));
  }

  /**
   * @notice Set players.
   */
  function _setPlayers(EntityId entityId, address[] memory players) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((players)));
  }

  /**
   * @notice Set players (using the specified store).
   */
  function setPlayers(IStore _store, EntityId entityId, address[] memory players) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    _store.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((players)));
  }

  /**
   * @notice Get the length of players.
   */
  function lengthPlayers(EntityId entityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    uint256 _byteLength = StoreSwitch.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 20;
    }
  }

  /**
   * @notice Get the length of players.
   */
  function _lengthPlayers(EntityId entityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    uint256 _byteLength = StoreCore.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 20;
    }
  }

  /**
   * @notice Get the length of players (using the specified store).
   */
  function lengthPlayers(IStore _store, EntityId entityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    uint256 _byteLength = _store.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 20;
    }
  }

  /**
   * @notice Get an item of players.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItemPlayers(EntityId entityId, uint256 _index) internal view returns (address) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _blob = StoreSwitch.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 20, (_index + 1) * 20);
      return (address(bytes20(_blob)));
    }
  }

  /**
   * @notice Get an item of players.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function _getItemPlayers(EntityId entityId, uint256 _index) internal view returns (address) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _blob = StoreCore.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 20, (_index + 1) * 20);
      return (address(bytes20(_blob)));
    }
  }

  /**
   * @notice Get an item of players (using the specified store).
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItemPlayers(IStore _store, EntityId entityId, uint256 _index) internal view returns (address) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _blob = _store.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 20, (_index + 1) * 20);
      return (address(bytes20(_blob)));
    }
  }

  /**
   * @notice Push an element to players.
   */
  function pushPlayers(EntityId entityId, address _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to players.
   */
  function _pushPlayers(EntityId entityId, address _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to players (using the specified store).
   */
  function pushPlayers(IStore _store, EntityId entityId, address _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    _store.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Pop an element from players.
   */
  function popPlayers(EntityId entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.popFromDynamicField(_tableId, _keyTuple, 0, 20);
  }

  /**
   * @notice Pop an element from players.
   */
  function _popPlayers(EntityId entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.popFromDynamicField(_tableId, _keyTuple, 0, 20);
  }

  /**
   * @notice Pop an element from players (using the specified store).
   */
  function popPlayers(IStore _store, EntityId entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    _store.popFromDynamicField(_tableId, _keyTuple, 0, 20);
  }

  /**
   * @notice Update an element of players at `_index`.
   */
  function updatePlayers(EntityId entityId, uint256 _index, address _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreSwitch.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 20), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of players at `_index`.
   */
  function _updatePlayers(EntityId entityId, uint256 _index, address _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreCore.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 20), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of players (using the specified store) at `_index`.
   */
  function updatePlayers(IStore _store, EntityId entityId, uint256 _index, address _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      _store.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 20), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Get nfts.
   */
  function getNfts(EntityId entityId) internal view returns (address[] memory nfts) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    bytes memory _blob = StoreSwitch.getDynamicField(_tableId, _keyTuple, 1);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_address());
  }

  /**
   * @notice Get nfts.
   */
  function _getNfts(EntityId entityId) internal view returns (address[] memory nfts) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    bytes memory _blob = StoreCore.getDynamicField(_tableId, _keyTuple, 1);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_address());
  }

  /**
   * @notice Get nfts (using the specified store).
   */
  function getNfts(IStore _store, EntityId entityId) internal view returns (address[] memory nfts) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    bytes memory _blob = _store.getDynamicField(_tableId, _keyTuple, 1);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_address());
  }

  /**
   * @notice Set nfts.
   */
  function setNfts(EntityId entityId, address[] memory nfts) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.setDynamicField(_tableId, _keyTuple, 1, EncodeArray.encode((nfts)));
  }

  /**
   * @notice Set nfts.
   */
  function _setNfts(EntityId entityId, address[] memory nfts) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.setDynamicField(_tableId, _keyTuple, 1, EncodeArray.encode((nfts)));
  }

  /**
   * @notice Set nfts (using the specified store).
   */
  function setNfts(IStore _store, EntityId entityId, address[] memory nfts) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    _store.setDynamicField(_tableId, _keyTuple, 1, EncodeArray.encode((nfts)));
  }

  /**
   * @notice Get the length of nfts.
   */
  function lengthNfts(EntityId entityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    uint256 _byteLength = StoreSwitch.getDynamicFieldLength(_tableId, _keyTuple, 1);
    unchecked {
      return _byteLength / 20;
    }
  }

  /**
   * @notice Get the length of nfts.
   */
  function _lengthNfts(EntityId entityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    uint256 _byteLength = StoreCore.getDynamicFieldLength(_tableId, _keyTuple, 1);
    unchecked {
      return _byteLength / 20;
    }
  }

  /**
   * @notice Get the length of nfts (using the specified store).
   */
  function lengthNfts(IStore _store, EntityId entityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    uint256 _byteLength = _store.getDynamicFieldLength(_tableId, _keyTuple, 1);
    unchecked {
      return _byteLength / 20;
    }
  }

  /**
   * @notice Get an item of nfts.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItemNfts(EntityId entityId, uint256 _index) internal view returns (address) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _blob = StoreSwitch.getDynamicFieldSlice(_tableId, _keyTuple, 1, _index * 20, (_index + 1) * 20);
      return (address(bytes20(_blob)));
    }
  }

  /**
   * @notice Get an item of nfts.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function _getItemNfts(EntityId entityId, uint256 _index) internal view returns (address) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _blob = StoreCore.getDynamicFieldSlice(_tableId, _keyTuple, 1, _index * 20, (_index + 1) * 20);
      return (address(bytes20(_blob)));
    }
  }

  /**
   * @notice Get an item of nfts (using the specified store).
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItemNfts(IStore _store, EntityId entityId, uint256 _index) internal view returns (address) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _blob = _store.getDynamicFieldSlice(_tableId, _keyTuple, 1, _index * 20, (_index + 1) * 20);
      return (address(bytes20(_blob)));
    }
  }

  /**
   * @notice Push an element to nfts.
   */
  function pushNfts(EntityId entityId, address _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.pushToDynamicField(_tableId, _keyTuple, 1, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to nfts.
   */
  function _pushNfts(EntityId entityId, address _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.pushToDynamicField(_tableId, _keyTuple, 1, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to nfts (using the specified store).
   */
  function pushNfts(IStore _store, EntityId entityId, address _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    _store.pushToDynamicField(_tableId, _keyTuple, 1, abi.encodePacked((_element)));
  }

  /**
   * @notice Pop an element from nfts.
   */
  function popNfts(EntityId entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.popFromDynamicField(_tableId, _keyTuple, 1, 20);
  }

  /**
   * @notice Pop an element from nfts.
   */
  function _popNfts(EntityId entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.popFromDynamicField(_tableId, _keyTuple, 1, 20);
  }

  /**
   * @notice Pop an element from nfts (using the specified store).
   */
  function popNfts(IStore _store, EntityId entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    _store.popFromDynamicField(_tableId, _keyTuple, 1, 20);
  }

  /**
   * @notice Update an element of nfts at `_index`.
   */
  function updateNfts(EntityId entityId, uint256 _index, address _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreSwitch.spliceDynamicData(_tableId, _keyTuple, 1, uint40(_index * 20), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of nfts at `_index`.
   */
  function _updateNfts(EntityId entityId, uint256 _index, address _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreCore.spliceDynamicData(_tableId, _keyTuple, 1, uint40(_index * 20), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of nfts (using the specified store) at `_index`.
   */
  function updateNfts(IStore _store, EntityId entityId, uint256 _index, address _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      _store.spliceDynamicData(_tableId, _keyTuple, 1, uint40(_index * 20), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Get the full data.
   */
  function get(EntityId entityId) internal view returns (GateApprovalsData memory _table) {
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
  function _get(EntityId entityId) internal view returns (GateApprovalsData memory _table) {
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
   * @notice Get the full data (using the specified store).
   */
  function get(IStore _store, EntityId entityId) internal view returns (GateApprovalsData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

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
  function set(EntityId entityId, address[] memory players, address[] memory nfts) internal {
    bytes memory _staticData;
    EncodedLengths _encodedLengths = encodeLengths(players, nfts);
    bytes memory _dynamicData = encodeDynamic(players, nfts);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function _set(EntityId entityId, address[] memory players, address[] memory nfts) internal {
    bytes memory _staticData;
    EncodedLengths _encodedLengths = encodeLengths(players, nfts);
    bytes memory _dynamicData = encodeDynamic(players, nfts);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Set the full data using individual values (using the specified store).
   */
  function set(IStore _store, EntityId entityId, address[] memory players, address[] memory nfts) internal {
    bytes memory _staticData;
    EncodedLengths _encodedLengths = encodeLengths(players, nfts);
    bytes memory _dynamicData = encodeDynamic(players, nfts);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    _store.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function set(EntityId entityId, GateApprovalsData memory _table) internal {
    bytes memory _staticData;
    EncodedLengths _encodedLengths = encodeLengths(_table.players, _table.nfts);
    bytes memory _dynamicData = encodeDynamic(_table.players, _table.nfts);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function _set(EntityId entityId, GateApprovalsData memory _table) internal {
    bytes memory _staticData;
    EncodedLengths _encodedLengths = encodeLengths(_table.players, _table.nfts);
    bytes memory _dynamicData = encodeDynamic(_table.players, _table.nfts);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Set the full data using the data struct (using the specified store).
   */
  function set(IStore _store, EntityId entityId, GateApprovalsData memory _table) internal {
    bytes memory _staticData;
    EncodedLengths _encodedLengths = encodeLengths(_table.players, _table.nfts);
    bytes memory _dynamicData = encodeDynamic(_table.players, _table.nfts);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    _store.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Decode the tightly packed blob of dynamic data using the encoded lengths.
   */
  function decodeDynamic(
    EncodedLengths _encodedLengths,
    bytes memory _blob
  ) internal pure returns (address[] memory players, address[] memory nfts) {
    uint256 _start;
    uint256 _end;
    unchecked {
      _end = _encodedLengths.atIndex(0);
    }
    players = (SliceLib.getSubslice(_blob, _start, _end).decodeArray_address());

    _start = _end;
    unchecked {
      _end += _encodedLengths.atIndex(1);
    }
    nfts = (SliceLib.getSubslice(_blob, _start, _end).decodeArray_address());
  }

  /**
   * @notice Decode the tightly packed blobs using this table's field layout.
   *
   * @param _encodedLengths Encoded lengths of dynamic fields.
   * @param _dynamicData Tightly packed dynamic fields.
   */
  function decode(
    bytes memory,
    EncodedLengths _encodedLengths,
    bytes memory _dynamicData
  ) internal pure returns (GateApprovalsData memory _table) {
    (_table.players, _table.nfts) = decodeDynamic(_encodedLengths, _dynamicData);
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
  function encodeLengths(
    address[] memory players,
    address[] memory nfts
  ) internal pure returns (EncodedLengths _encodedLengths) {
    // Lengths are effectively checked during copy by 2**40 bytes exceeding gas limits
    unchecked {
      _encodedLengths = EncodedLengthsLib.pack(players.length * 20, nfts.length * 20);
    }
  }

  /**
   * @notice Tightly pack dynamic (variable length) data using this table's schema.
   * @return The dynamic data, encoded into a sequence of bytes.
   */
  function encodeDynamic(address[] memory players, address[] memory nfts) internal pure returns (bytes memory) {
    return abi.encodePacked(EncodeArray.encode((players)), EncodeArray.encode((nfts)));
  }

  /**
   * @notice Encode all of a record's fields.
   * @return The static (fixed length) data, encoded into a sequence of bytes.
   * @return The lengths of the dynamic fields (packed into a single bytes32 value).
   * @return The dynamic (variable length) data, encoded into a sequence of bytes.
   */
  function encode(
    address[] memory players,
    address[] memory nfts
  ) internal pure returns (bytes memory, EncodedLengths, bytes memory) {
    bytes memory _staticData;
    EncodedLengths _encodedLengths = encodeLengths(players, nfts);
    bytes memory _dynamicData = encodeDynamic(players, nfts);

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
