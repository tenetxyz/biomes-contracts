// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Player } from "../codegen/tables/Player.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { ItemMetadata } from "../codegen/tables/ItemMetadata.sol";
import { ExperiencePoints } from "../codegen/tables/ExperiencePoints.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";

import { positionDataToVoxelCoord } from "../Utils.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID } from "../ObjectTypeIds.sol";
import { regenHealth, regenStamina } from "../utils/PlayerUtils.sol";
import { mintXP } from "../utils/XPUtils.sol";

contract UnequipSystem is System {
  function unequip() public {
    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "UnequipSystem: player does not exist");
    require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "UnequipSystem: player isn't logged in");

    VoxelCoord memory playerCoord = positionDataToVoxelCoord(Position._get(playerEntityId));
    regenHealth(playerEntityId);
    regenStamina(playerEntityId, playerCoord);

    if (Equipped._get(playerEntityId) != bytes32(0)) {
      Equipped._deleteRecord(playerEntityId);
    }

    PlayerActivity._set(playerEntityId, block.timestamp);
    mintXP(playerEntityId, 1);
  }
}
