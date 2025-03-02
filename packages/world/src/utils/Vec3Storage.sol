// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

library Position {
  function get(EntityId entityId) internal view returns (Vec3 position) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return Vec3.wrap(uint96(bytes12(_blob)));
  }

  /**
   * @notice Get position.
   */
  function _get(EntityId entityId) internal view returns (Vec3 position) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return Vec3.wrap(uint96(bytes12(_blob)));
  }

  function set(EntityId entityId, Vec3 position) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreSwitch.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked(Vec3.unwrap(position)), _fieldLayout);
  }

  /**
   * @notice Set position.
   */
  function _set(EntityId entityId, Vec3 position) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = EntityId.unwrap(entityId);

    StoreCore.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked(Vec3.unwrap(position)), _fieldLayout);
  }

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
}

library ReversePosition {
  function get(Vec3 position) internal view returns (EntityId entityId) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(Vec3.unwrap(position)));

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return EntityId.wrap(bytes32(_blob));
  }

  /**
   * @notice Get entityId.
   */
  function _get(Vec3 position) internal view returns (EntityId entityId) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(Vec3.unwrap(position)));

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return EntityId.wrap(bytes32(_blob));
  }

  function set(Vec3 position, EntityId entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(Vec3.unwrap(position)));

    StoreSwitch.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked(EntityId.unwrap(entityId)), _fieldLayout);
  }

  /**
   * @notice Set entityId.
   */
  function _set(Vec3 position, EntityId entityId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(Vec3.unwrap(position)));

    StoreCore.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked(EntityId.unwrap(entityId)), _fieldLayout);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function deleteRecord(Vec3 position) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(Vec3.unwrap(position)));

    StoreSwitch.deleteRecord(_tableId, _keyTuple);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function _deleteRecord(Vec3 position) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = bytes32(uint256(Vec3.unwrap(position)));

    StoreCore.deleteRecord(_tableId, _keyTuple, _fieldLayout);
  }
}
