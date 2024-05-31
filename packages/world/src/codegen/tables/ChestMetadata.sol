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

struct ChestMetadataData {
  address owner;
  address onTransferHook;
  uint256 strength;
  uint8[] strengthenObjectTypeIds;
  uint16[] strengthenObjectTypeAmounts;
}

library ChestMetadata {
  // Hex below is the result of `WorldResourceIdLib.encode({ namespace: "", name: "ChestMetadata", typeId: RESOURCE_TABLE });`
  ResourceId constant _tableId = ResourceId.wrap(0x7462000000000000000000000000000043686573744d65746164617461000000);

  FieldLayout constant _fieldLayout =
    FieldLayout.wrap(0x0048030214142000000000000000000000000000000000000000000000000000);

  // Hex-encoded key schema of (bytes32)
  Schema constant _keySchema = Schema.wrap(0x002001005f000000000000000000000000000000000000000000000000000000);
  // Hex-encoded value schema of (address, address, uint256, uint8[], uint16[])
  Schema constant _valueSchema = Schema.wrap(0x0048030261611f62630000000000000000000000000000000000000000000000);

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
    fieldNames = new string[](5);
    fieldNames[0] = "owner";
    fieldNames[1] = "onTransferHook";
    fieldNames[2] = "strength";
    fieldNames[3] = "strengthenObjectTypeIds";
    fieldNames[4] = "strengthenObjectTypeAmounts";
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
   * @notice Get owner.
   */
  function getOwner(bytes32 chestEntityId) internal view returns (address owner) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (address(bytes20(_blob)));
  }

  /**
   * @notice Get owner.
   */
  function _getOwner(bytes32 chestEntityId) internal view returns (address owner) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (address(bytes20(_blob)));
  }

  /**
   * @notice Get owner (using the specified store).
   */
  function getOwner(IStore _store, bytes32 chestEntityId) internal view returns (address owner) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    bytes32 _blob = _store.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (address(bytes20(_blob)));
  }

  /**
   * @notice Set owner.
   */
  function setOwner(bytes32 chestEntityId, address owner) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((owner)), _fieldLayout);
  }

  /**
   * @notice Set owner.
   */
  function _setOwner(bytes32 chestEntityId, address owner) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreCore.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((owner)), _fieldLayout);
  }

  /**
   * @notice Set owner (using the specified store).
   */
  function setOwner(IStore _store, bytes32 chestEntityId, address owner) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    _store.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((owner)), _fieldLayout);
  }

  /**
   * @notice Get onTransferHook.
   */
  function getOnTransferHook(bytes32 chestEntityId) internal view returns (address onTransferHook) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 1, _fieldLayout);
    return (address(bytes20(_blob)));
  }

  /**
   * @notice Get onTransferHook.
   */
  function _getOnTransferHook(bytes32 chestEntityId) internal view returns (address onTransferHook) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 1, _fieldLayout);
    return (address(bytes20(_blob)));
  }

  /**
   * @notice Get onTransferHook (using the specified store).
   */
  function getOnTransferHook(IStore _store, bytes32 chestEntityId) internal view returns (address onTransferHook) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    bytes32 _blob = _store.getStaticField(_tableId, _keyTuple, 1, _fieldLayout);
    return (address(bytes20(_blob)));
  }

  /**
   * @notice Set onTransferHook.
   */
  function setOnTransferHook(bytes32 chestEntityId, address onTransferHook) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked((onTransferHook)), _fieldLayout);
  }

  /**
   * @notice Set onTransferHook.
   */
  function _setOnTransferHook(bytes32 chestEntityId, address onTransferHook) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreCore.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked((onTransferHook)), _fieldLayout);
  }

  /**
   * @notice Set onTransferHook (using the specified store).
   */
  function setOnTransferHook(IStore _store, bytes32 chestEntityId, address onTransferHook) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    _store.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked((onTransferHook)), _fieldLayout);
  }

  /**
   * @notice Get strength.
   */
  function getStrength(bytes32 chestEntityId) internal view returns (uint256 strength) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 2, _fieldLayout);
    return (uint256(bytes32(_blob)));
  }

  /**
   * @notice Get strength.
   */
  function _getStrength(bytes32 chestEntityId) internal view returns (uint256 strength) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 2, _fieldLayout);
    return (uint256(bytes32(_blob)));
  }

  /**
   * @notice Get strength (using the specified store).
   */
  function getStrength(IStore _store, bytes32 chestEntityId) internal view returns (uint256 strength) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    bytes32 _blob = _store.getStaticField(_tableId, _keyTuple, 2, _fieldLayout);
    return (uint256(bytes32(_blob)));
  }

  /**
   * @notice Set strength.
   */
  function setStrength(bytes32 chestEntityId, uint256 strength) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 2, abi.encodePacked((strength)), _fieldLayout);
  }

  /**
   * @notice Set strength.
   */
  function _setStrength(bytes32 chestEntityId, uint256 strength) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreCore.setStaticField(_tableId, _keyTuple, 2, abi.encodePacked((strength)), _fieldLayout);
  }

  /**
   * @notice Set strength (using the specified store).
   */
  function setStrength(IStore _store, bytes32 chestEntityId, uint256 strength) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    _store.setStaticField(_tableId, _keyTuple, 2, abi.encodePacked((strength)), _fieldLayout);
  }

  /**
   * @notice Get strengthenObjectTypeIds.
   */
  function getStrengthenObjectTypeIds(
    bytes32 chestEntityId
  ) internal view returns (uint8[] memory strengthenObjectTypeIds) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    bytes memory _blob = StoreSwitch.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_uint8());
  }

  /**
   * @notice Get strengthenObjectTypeIds.
   */
  function _getStrengthenObjectTypeIds(
    bytes32 chestEntityId
  ) internal view returns (uint8[] memory strengthenObjectTypeIds) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    bytes memory _blob = StoreCore.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_uint8());
  }

  /**
   * @notice Get strengthenObjectTypeIds (using the specified store).
   */
  function getStrengthenObjectTypeIds(
    IStore _store,
    bytes32 chestEntityId
  ) internal view returns (uint8[] memory strengthenObjectTypeIds) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    bytes memory _blob = _store.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_uint8());
  }

  /**
   * @notice Set strengthenObjectTypeIds.
   */
  function setStrengthenObjectTypeIds(bytes32 chestEntityId, uint8[] memory strengthenObjectTypeIds) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((strengthenObjectTypeIds)));
  }

  /**
   * @notice Set strengthenObjectTypeIds.
   */
  function _setStrengthenObjectTypeIds(bytes32 chestEntityId, uint8[] memory strengthenObjectTypeIds) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreCore.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((strengthenObjectTypeIds)));
  }

  /**
   * @notice Set strengthenObjectTypeIds (using the specified store).
   */
  function setStrengthenObjectTypeIds(
    IStore _store,
    bytes32 chestEntityId,
    uint8[] memory strengthenObjectTypeIds
  ) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    _store.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((strengthenObjectTypeIds)));
  }

  /**
   * @notice Get the length of strengthenObjectTypeIds.
   */
  function lengthStrengthenObjectTypeIds(bytes32 chestEntityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    uint256 _byteLength = StoreSwitch.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 1;
    }
  }

  /**
   * @notice Get the length of strengthenObjectTypeIds.
   */
  function _lengthStrengthenObjectTypeIds(bytes32 chestEntityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    uint256 _byteLength = StoreCore.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 1;
    }
  }

  /**
   * @notice Get the length of strengthenObjectTypeIds (using the specified store).
   */
  function lengthStrengthenObjectTypeIds(IStore _store, bytes32 chestEntityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    uint256 _byteLength = _store.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 1;
    }
  }

  /**
   * @notice Get an item of strengthenObjectTypeIds.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItemStrengthenObjectTypeIds(bytes32 chestEntityId, uint256 _index) internal view returns (uint8) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    unchecked {
      bytes memory _blob = StoreSwitch.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 1, (_index + 1) * 1);
      return (uint8(bytes1(_blob)));
    }
  }

  /**
   * @notice Get an item of strengthenObjectTypeIds.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function _getItemStrengthenObjectTypeIds(bytes32 chestEntityId, uint256 _index) internal view returns (uint8) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    unchecked {
      bytes memory _blob = StoreCore.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 1, (_index + 1) * 1);
      return (uint8(bytes1(_blob)));
    }
  }

  /**
   * @notice Get an item of strengthenObjectTypeIds (using the specified store).
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItemStrengthenObjectTypeIds(
    IStore _store,
    bytes32 chestEntityId,
    uint256 _index
  ) internal view returns (uint8) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    unchecked {
      bytes memory _blob = _store.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 1, (_index + 1) * 1);
      return (uint8(bytes1(_blob)));
    }
  }

  /**
   * @notice Push an element to strengthenObjectTypeIds.
   */
  function pushStrengthenObjectTypeIds(bytes32 chestEntityId, uint8 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to strengthenObjectTypeIds.
   */
  function _pushStrengthenObjectTypeIds(bytes32 chestEntityId, uint8 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreCore.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to strengthenObjectTypeIds (using the specified store).
   */
  function pushStrengthenObjectTypeIds(IStore _store, bytes32 chestEntityId, uint8 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    _store.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Pop an element from strengthenObjectTypeIds.
   */
  function popStrengthenObjectTypeIds(bytes32 chestEntityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.popFromDynamicField(_tableId, _keyTuple, 0, 1);
  }

  /**
   * @notice Pop an element from strengthenObjectTypeIds.
   */
  function _popStrengthenObjectTypeIds(bytes32 chestEntityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreCore.popFromDynamicField(_tableId, _keyTuple, 0, 1);
  }

  /**
   * @notice Pop an element from strengthenObjectTypeIds (using the specified store).
   */
  function popStrengthenObjectTypeIds(IStore _store, bytes32 chestEntityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    _store.popFromDynamicField(_tableId, _keyTuple, 0, 1);
  }

  /**
   * @notice Update an element of strengthenObjectTypeIds at `_index`.
   */
  function updateStrengthenObjectTypeIds(bytes32 chestEntityId, uint256 _index, uint8 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreSwitch.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 1), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of strengthenObjectTypeIds at `_index`.
   */
  function _updateStrengthenObjectTypeIds(bytes32 chestEntityId, uint256 _index, uint8 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreCore.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 1), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of strengthenObjectTypeIds (using the specified store) at `_index`.
   */
  function updateStrengthenObjectTypeIds(
    IStore _store,
    bytes32 chestEntityId,
    uint256 _index,
    uint8 _element
  ) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      _store.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 1), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Get strengthenObjectTypeAmounts.
   */
  function getStrengthenObjectTypeAmounts(
    bytes32 chestEntityId
  ) internal view returns (uint16[] memory strengthenObjectTypeAmounts) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    bytes memory _blob = StoreSwitch.getDynamicField(_tableId, _keyTuple, 1);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_uint16());
  }

  /**
   * @notice Get strengthenObjectTypeAmounts.
   */
  function _getStrengthenObjectTypeAmounts(
    bytes32 chestEntityId
  ) internal view returns (uint16[] memory strengthenObjectTypeAmounts) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    bytes memory _blob = StoreCore.getDynamicField(_tableId, _keyTuple, 1);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_uint16());
  }

  /**
   * @notice Get strengthenObjectTypeAmounts (using the specified store).
   */
  function getStrengthenObjectTypeAmounts(
    IStore _store,
    bytes32 chestEntityId
  ) internal view returns (uint16[] memory strengthenObjectTypeAmounts) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    bytes memory _blob = _store.getDynamicField(_tableId, _keyTuple, 1);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_uint16());
  }

  /**
   * @notice Set strengthenObjectTypeAmounts.
   */
  function setStrengthenObjectTypeAmounts(bytes32 chestEntityId, uint16[] memory strengthenObjectTypeAmounts) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.setDynamicField(_tableId, _keyTuple, 1, EncodeArray.encode((strengthenObjectTypeAmounts)));
  }

  /**
   * @notice Set strengthenObjectTypeAmounts.
   */
  function _setStrengthenObjectTypeAmounts(
    bytes32 chestEntityId,
    uint16[] memory strengthenObjectTypeAmounts
  ) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreCore.setDynamicField(_tableId, _keyTuple, 1, EncodeArray.encode((strengthenObjectTypeAmounts)));
  }

  /**
   * @notice Set strengthenObjectTypeAmounts (using the specified store).
   */
  function setStrengthenObjectTypeAmounts(
    IStore _store,
    bytes32 chestEntityId,
    uint16[] memory strengthenObjectTypeAmounts
  ) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    _store.setDynamicField(_tableId, _keyTuple, 1, EncodeArray.encode((strengthenObjectTypeAmounts)));
  }

  /**
   * @notice Get the length of strengthenObjectTypeAmounts.
   */
  function lengthStrengthenObjectTypeAmounts(bytes32 chestEntityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    uint256 _byteLength = StoreSwitch.getDynamicFieldLength(_tableId, _keyTuple, 1);
    unchecked {
      return _byteLength / 2;
    }
  }

  /**
   * @notice Get the length of strengthenObjectTypeAmounts.
   */
  function _lengthStrengthenObjectTypeAmounts(bytes32 chestEntityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    uint256 _byteLength = StoreCore.getDynamicFieldLength(_tableId, _keyTuple, 1);
    unchecked {
      return _byteLength / 2;
    }
  }

  /**
   * @notice Get the length of strengthenObjectTypeAmounts (using the specified store).
   */
  function lengthStrengthenObjectTypeAmounts(IStore _store, bytes32 chestEntityId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    uint256 _byteLength = _store.getDynamicFieldLength(_tableId, _keyTuple, 1);
    unchecked {
      return _byteLength / 2;
    }
  }

  /**
   * @notice Get an item of strengthenObjectTypeAmounts.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItemStrengthenObjectTypeAmounts(bytes32 chestEntityId, uint256 _index) internal view returns (uint16) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    unchecked {
      bytes memory _blob = StoreSwitch.getDynamicFieldSlice(_tableId, _keyTuple, 1, _index * 2, (_index + 1) * 2);
      return (uint16(bytes2(_blob)));
    }
  }

  /**
   * @notice Get an item of strengthenObjectTypeAmounts.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function _getItemStrengthenObjectTypeAmounts(bytes32 chestEntityId, uint256 _index) internal view returns (uint16) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    unchecked {
      bytes memory _blob = StoreCore.getDynamicFieldSlice(_tableId, _keyTuple, 1, _index * 2, (_index + 1) * 2);
      return (uint16(bytes2(_blob)));
    }
  }

  /**
   * @notice Get an item of strengthenObjectTypeAmounts (using the specified store).
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItemStrengthenObjectTypeAmounts(
    IStore _store,
    bytes32 chestEntityId,
    uint256 _index
  ) internal view returns (uint16) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    unchecked {
      bytes memory _blob = _store.getDynamicFieldSlice(_tableId, _keyTuple, 1, _index * 2, (_index + 1) * 2);
      return (uint16(bytes2(_blob)));
    }
  }

  /**
   * @notice Push an element to strengthenObjectTypeAmounts.
   */
  function pushStrengthenObjectTypeAmounts(bytes32 chestEntityId, uint16 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.pushToDynamicField(_tableId, _keyTuple, 1, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to strengthenObjectTypeAmounts.
   */
  function _pushStrengthenObjectTypeAmounts(bytes32 chestEntityId, uint16 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreCore.pushToDynamicField(_tableId, _keyTuple, 1, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to strengthenObjectTypeAmounts (using the specified store).
   */
  function pushStrengthenObjectTypeAmounts(IStore _store, bytes32 chestEntityId, uint16 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    _store.pushToDynamicField(_tableId, _keyTuple, 1, abi.encodePacked((_element)));
  }

  /**
   * @notice Pop an element from strengthenObjectTypeAmounts.
   */
  function popStrengthenObjectTypeAmounts(bytes32 chestEntityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.popFromDynamicField(_tableId, _keyTuple, 1, 2);
  }

  /**
   * @notice Pop an element from strengthenObjectTypeAmounts.
   */
  function _popStrengthenObjectTypeAmounts(bytes32 chestEntityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreCore.popFromDynamicField(_tableId, _keyTuple, 1, 2);
  }

  /**
   * @notice Pop an element from strengthenObjectTypeAmounts (using the specified store).
   */
  function popStrengthenObjectTypeAmounts(IStore _store, bytes32 chestEntityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    _store.popFromDynamicField(_tableId, _keyTuple, 1, 2);
  }

  /**
   * @notice Update an element of strengthenObjectTypeAmounts at `_index`.
   */
  function updateStrengthenObjectTypeAmounts(bytes32 chestEntityId, uint256 _index, uint16 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreSwitch.spliceDynamicData(_tableId, _keyTuple, 1, uint40(_index * 2), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of strengthenObjectTypeAmounts at `_index`.
   */
  function _updateStrengthenObjectTypeAmounts(bytes32 chestEntityId, uint256 _index, uint16 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreCore.spliceDynamicData(_tableId, _keyTuple, 1, uint40(_index * 2), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of strengthenObjectTypeAmounts (using the specified store) at `_index`.
   */
  function updateStrengthenObjectTypeAmounts(
    IStore _store,
    bytes32 chestEntityId,
    uint256 _index,
    uint16 _element
  ) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      _store.spliceDynamicData(_tableId, _keyTuple, 1, uint40(_index * 2), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Get the full data.
   */
  function get(bytes32 chestEntityId) internal view returns (ChestMetadataData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

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
  function _get(bytes32 chestEntityId) internal view returns (ChestMetadataData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

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
  function get(IStore _store, bytes32 chestEntityId) internal view returns (ChestMetadataData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

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
    bytes32 chestEntityId,
    address owner,
    address onTransferHook,
    uint256 strength,
    uint8[] memory strengthenObjectTypeIds,
    uint16[] memory strengthenObjectTypeAmounts
  ) internal {
    bytes memory _staticData = encodeStatic(owner, onTransferHook, strength);

    EncodedLengths _encodedLengths = encodeLengths(strengthenObjectTypeIds, strengthenObjectTypeAmounts);
    bytes memory _dynamicData = encodeDynamic(strengthenObjectTypeIds, strengthenObjectTypeAmounts);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function _set(
    bytes32 chestEntityId,
    address owner,
    address onTransferHook,
    uint256 strength,
    uint8[] memory strengthenObjectTypeIds,
    uint16[] memory strengthenObjectTypeAmounts
  ) internal {
    bytes memory _staticData = encodeStatic(owner, onTransferHook, strength);

    EncodedLengths _encodedLengths = encodeLengths(strengthenObjectTypeIds, strengthenObjectTypeAmounts);
    bytes memory _dynamicData = encodeDynamic(strengthenObjectTypeIds, strengthenObjectTypeAmounts);

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
    address owner,
    address onTransferHook,
    uint256 strength,
    uint8[] memory strengthenObjectTypeIds,
    uint16[] memory strengthenObjectTypeAmounts
  ) internal {
    bytes memory _staticData = encodeStatic(owner, onTransferHook, strength);

    EncodedLengths _encodedLengths = encodeLengths(strengthenObjectTypeIds, strengthenObjectTypeAmounts);
    bytes memory _dynamicData = encodeDynamic(strengthenObjectTypeIds, strengthenObjectTypeAmounts);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    _store.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function set(bytes32 chestEntityId, ChestMetadataData memory _table) internal {
    bytes memory _staticData = encodeStatic(_table.owner, _table.onTransferHook, _table.strength);

    EncodedLengths _encodedLengths = encodeLengths(_table.strengthenObjectTypeIds, _table.strengthenObjectTypeAmounts);
    bytes memory _dynamicData = encodeDynamic(_table.strengthenObjectTypeIds, _table.strengthenObjectTypeAmounts);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function _set(bytes32 chestEntityId, ChestMetadataData memory _table) internal {
    bytes memory _staticData = encodeStatic(_table.owner, _table.onTransferHook, _table.strength);

    EncodedLengths _encodedLengths = encodeLengths(_table.strengthenObjectTypeIds, _table.strengthenObjectTypeAmounts);
    bytes memory _dynamicData = encodeDynamic(_table.strengthenObjectTypeIds, _table.strengthenObjectTypeAmounts);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Set the full data using the data struct (using the specified store).
   */
  function set(IStore _store, bytes32 chestEntityId, ChestMetadataData memory _table) internal {
    bytes memory _staticData = encodeStatic(_table.owner, _table.onTransferHook, _table.strength);

    EncodedLengths _encodedLengths = encodeLengths(_table.strengthenObjectTypeIds, _table.strengthenObjectTypeAmounts);
    bytes memory _dynamicData = encodeDynamic(_table.strengthenObjectTypeIds, _table.strengthenObjectTypeAmounts);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = chestEntityId;

    _store.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Decode the tightly packed blob of static data using this table's field layout.
   */
  function decodeStatic(
    bytes memory _blob
  ) internal pure returns (address owner, address onTransferHook, uint256 strength) {
    owner = (address(Bytes.getBytes20(_blob, 0)));

    onTransferHook = (address(Bytes.getBytes20(_blob, 20)));

    strength = (uint256(Bytes.getBytes32(_blob, 40)));
  }

  /**
   * @notice Decode the tightly packed blob of dynamic data using the encoded lengths.
   */
  function decodeDynamic(
    EncodedLengths _encodedLengths,
    bytes memory _blob
  ) internal pure returns (uint8[] memory strengthenObjectTypeIds, uint16[] memory strengthenObjectTypeAmounts) {
    uint256 _start;
    uint256 _end;
    unchecked {
      _end = _encodedLengths.atIndex(0);
    }
    strengthenObjectTypeIds = (SliceLib.getSubslice(_blob, _start, _end).decodeArray_uint8());

    _start = _end;
    unchecked {
      _end += _encodedLengths.atIndex(1);
    }
    strengthenObjectTypeAmounts = (SliceLib.getSubslice(_blob, _start, _end).decodeArray_uint16());
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
  ) internal pure returns (ChestMetadataData memory _table) {
    (_table.owner, _table.onTransferHook, _table.strength) = decodeStatic(_staticData);

    (_table.strengthenObjectTypeIds, _table.strengthenObjectTypeAmounts) = decodeDynamic(_encodedLengths, _dynamicData);
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
  function encodeStatic(address owner, address onTransferHook, uint256 strength) internal pure returns (bytes memory) {
    return abi.encodePacked(owner, onTransferHook, strength);
  }

  /**
   * @notice Tightly pack dynamic data lengths using this table's schema.
   * @return _encodedLengths The lengths of the dynamic fields (packed into a single bytes32 value).
   */
  function encodeLengths(
    uint8[] memory strengthenObjectTypeIds,
    uint16[] memory strengthenObjectTypeAmounts
  ) internal pure returns (EncodedLengths _encodedLengths) {
    // Lengths are effectively checked during copy by 2**40 bytes exceeding gas limits
    unchecked {
      _encodedLengths = EncodedLengthsLib.pack(
        strengthenObjectTypeIds.length * 1,
        strengthenObjectTypeAmounts.length * 2
      );
    }
  }

  /**
   * @notice Tightly pack dynamic (variable length) data using this table's schema.
   * @return The dynamic data, encoded into a sequence of bytes.
   */
  function encodeDynamic(
    uint8[] memory strengthenObjectTypeIds,
    uint16[] memory strengthenObjectTypeAmounts
  ) internal pure returns (bytes memory) {
    return
      abi.encodePacked(
        EncodeArray.encode((strengthenObjectTypeIds)),
        EncodeArray.encode((strengthenObjectTypeAmounts))
      );
  }

  /**
   * @notice Encode all of a record's fields.
   * @return The static (fixed length) data, encoded into a sequence of bytes.
   * @return The lengths of the dynamic fields (packed into a single bytes32 value).
   * @return The dynamic (variable length) data, encoded into a sequence of bytes.
   */
  function encode(
    address owner,
    address onTransferHook,
    uint256 strength,
    uint8[] memory strengthenObjectTypeIds,
    uint16[] memory strengthenObjectTypeAmounts
  ) internal pure returns (bytes memory, EncodedLengths, bytes memory) {
    bytes memory _staticData = encodeStatic(owner, onTransferHook, strength);

    EncodedLengths _encodedLengths = encodeLengths(strengthenObjectTypeIds, strengthenObjectTypeAmounts);
    bytes memory _dynamicData = encodeDynamic(strengthenObjectTypeIds, strengthenObjectTypeAmounts);

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
