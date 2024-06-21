// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { LastKnownPosition } from "../codegen/tables/LastKnownPosition.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Health } from "../codegen/tables/Health.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_RESPAWN_HALF_WIDTH, MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, PLAYER_HAND_DAMAGE, HIT_STAMINA_COST } from "../Constants.sol";
import { AirObjectID, PlayerObjectID, NullObjectTypeId } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord, lastKnownPositionDataToVoxelCoord } from "../Utils.sol";
import { useEquipped, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina, despawnPlayer } from "../utils/PlayerUtils.sol";
import { updateChipBatteryLevel } from "../utils/ChipUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

contract ActivateSystem is System {
  function activate(bytes32 entityId) public {
    require(entityId != bytes32(0), "ActivateSystem: entity does not exist");
    uint8 objectTypeId = ObjectType._get(entityId);
    require(objectTypeId != NullObjectTypeId, "ActivateSystem: entity has no object type");

    if (objectTypeId == PlayerObjectID) {
      require(!PlayerMetadata._getIsLoggedOff(entityId), "ActivateSystem: player isn't logged in");
      VoxelCoord memory playerCoord = positionDataToVoxelCoord(Position._get(entityId));
      regenHealth(entityId);
      regenStamina(entityId, playerCoord);
      PlayerActivity._set(entityId, block.timestamp);
    } else {
      // if there's no chip, it'll just do nothing
      updateChipBatteryLevel(entityId);
    }
  }
}
