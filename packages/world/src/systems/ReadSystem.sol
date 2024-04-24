// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";

import { OptionalSystemHooks } from "@latticexyz/world/src/codegen/tables/OptionalSystemHooks.sol";
import { UserDelegationControl } from "@latticexyz/world/src/codegen/tables/UserDelegationControl.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { NullObjectTypeId } from "@biomesaw/terrain/src/ObjectTypeIds.sol";
import { TERRAIN_WORLD_ADDRESS } from "../Constants.sol";

// Public getters so clients can read the world state
contract ReadSystem is System {
  function getOptionalSystemHooks(
    address player,
    ResourceId SystemId,
    bytes32 callDataHash
  ) public view returns (bytes21[] memory hooks) {
    return OptionalSystemHooks.getHooks(player, SystemId, callDataHash);
  }

  function getUserDelegation(
    address delegator,
    address delegatee
  ) public view returns (ResourceId delegationControlId) {
    return UserDelegationControl.getDelegationControlId(delegator, delegatee);
  }

  function getTerrainWorldAddress() public pure returns (address) {
    return TERRAIN_WORLD_ADDRESS;
  }

  function getObjectTypeIdAtCoord(VoxelCoord memory coord) public view returns (uint8) {
    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    if (entityId == bytes32(0)) {
      return NullObjectTypeId;
    }
    return ObjectType._get(entityId);
  }
}
