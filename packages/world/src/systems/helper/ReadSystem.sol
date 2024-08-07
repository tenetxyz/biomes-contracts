// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { OptionalSystemHooks } from "@latticexyz/world/src/codegen/tables/OptionalSystemHooks.sol";
import { UserDelegationControl } from "@latticexyz/world/src/codegen/tables/UserDelegationControl.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { ReversePosition } from "../../codegen/tables/ReversePosition.sol";
import { Player } from "../../codegen/tables/Player.sol";
import { Health, HealthData } from "../../codegen/tables/Health.sol";
import { Stamina, StaminaData } from "../../codegen/tables/Stamina.sol";
import { PlayerActivity } from "../../codegen/tables/PlayerActivity.sol";
import { PlayerMetadata } from "../../codegen/tables/PlayerMetadata.sol";

import { getTerrainObjectTypeId } from "../../Utils.sol";
import { NullObjectTypeId } from "../../ObjectTypeIds.sol";

// Public getters so clients can read the world state more easily
contract ReadSystem is System {
  function getOptionalSystemHooks(
    address player,
    ResourceId SystemId,
    bytes32 callDataHash
  ) public view returns (bytes21[] memory hooks) {
    return OptionalSystemHooks._getHooks(player, SystemId, callDataHash);
  }

  function getUserDelegation(
    address delegator,
    address delegatee
  ) public view returns (ResourceId delegationControlId) {
    return UserDelegationControl._getDelegationControlId(delegator, delegatee);
  }

  function getObjectTypeIdAtCoord(VoxelCoord memory coord) public view returns (uint8) {
    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    if (entityId == bytes32(0)) {
      return NullObjectTypeId;
    }
    return ObjectType._get(entityId);
  }

  function getObjectTypeIdAtCoordOrTerrain(VoxelCoord memory coord) public view returns (uint8) {
    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    if (entityId == bytes32(0)) {
      return getTerrainObjectTypeId(coord);
    }
    return ObjectType._get(entityId);
  }

  function getEntityIdAtCoord(VoxelCoord memory coord) public view returns (bytes32) {
    return ReversePosition._get(coord.x, coord.y, coord.z);
  }

  function getLastActivityTime(address player) public view returns (uint256) {
    bytes32 playerEntityId = Player._get(player);
    if (PlayerMetadata._getIsLoggedOff(playerEntityId)) {
      return 0;
    }
    return PlayerActivity._get(playerEntityId);
  }

  function getHealth(address player) public view returns (HealthData memory) {
    bytes32 playerEntityId = Player._get(player);
    require(playerEntityId != bytes32(0), "ReadSystem: player not found");
    return Health._get(playerEntityId);
  }

  function getStamina(address player) public view returns (StaminaData memory) {
    bytes32 playerEntityId = Player._get(player);
    require(playerEntityId != bytes32(0), "ReadSystem: player not found");
    return Stamina._get(playerEntityId);
  }
}
