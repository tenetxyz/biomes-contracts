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
import { ExperiencePoints } from "../codegen/tables/ExperiencePoints.sol";
import { BlockMetadata } from "../codegen/tables/BlockMetadata.sol";
import { WorldMetadata } from "../codegen/tables/WorldMetadata.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_RESPAWN_HALF_WIDTH, MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, PLAYER_HAND_DAMAGE, HIT_STAMINA_COST } from "../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID, ChestObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord, lastKnownPositionDataToVoxelCoord, gravityApplies, inWorldBorder, getTerrainObjectTypeId, getUniqueEntity } from "../Utils.sol";
import { useEquipped, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina, despawnPlayer } from "../utils/PlayerUtils.sol";
import { inSurroundingCube, inSurroundingCubeIgnoreY } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { calculateXPToBurnFromLogout, burnXP, mintXP, safeBurnXP } from "../utils/XPUtils.sol";

import { IBling } from "../../external/IBling.sol";

contract BlingSystem is System {
  function convertXPToBling(uint256 xpToConvert) public {
    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "BlingSystem: player does not exist");

    if (PlayerMetadata._getIsLoggedOff(playerEntityId)) {
      uint256 newXP = safeBurnXP(playerEntityId, calculateXPToBurnFromLogout(playerEntityId));
      require(newXP > 0, "BlingSystem: player has no XP to convert");
    }

    address blingAddress = WorldMetadata._getToken();
    require(blingAddress != address(0), "BlingSystem: bling contract not deployed");

    uint256 xpSupply = WorldMetadata._getXpSupply();
    uint256 blingSupply = IBling(blingAddress).totalSupply();

    uint256 blingToMint;
    if (blingSupply == 0) {
      // exchange rate is 1:1
      blingToMint = xpToConvert;
    } else {
      // exchange rate is based on the current supply of bling and xp
      blingToMint = (xpToConvert * blingSupply) / xpSupply;
    }

    burnXP(playerEntityId, xpToConvert);
    IBling(blingAddress).mint(_msgSender(), blingToMint);
  }

  function convertBlingToXP(uint256 blingToConvert) public {
    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "BlingSystem: player does not exist");

    if (PlayerMetadata._getIsLoggedOff(playerEntityId)) {
      uint256 newXP = safeBurnXP(playerEntityId, calculateXPToBurnFromLogout(playerEntityId));
      require(newXP > 0, "BlingSystem: player has no XP to convert");
    }

    address blingAddress = WorldMetadata._getToken();
    require(blingAddress != address(0), "BlingSystem: bling contract not deployed");

    uint256 xpSupply = WorldMetadata._getXpSupply();
    uint256 blingSupply = IBling(blingAddress).totalSupply();

    uint256 xpToMint;
    if (xpSupply == 0) {
      // exchange rate is 1:1
      xpToMint = blingToConvert;
    } else {
      // exchange rate is based on the current supply of bling and xp
      xpToMint = (blingToConvert * xpSupply) / blingSupply;
    }

    // Note: ERC20 will check if the player has enough bling to burn
    IBling(blingAddress).burn(_msgSender(), blingToConvert);
    mintXP(playerEntityId, xpToMint);
  }
}
