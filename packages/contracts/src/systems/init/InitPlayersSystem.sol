// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { PlayerObjectID } from "@biomesaw/terrain/src/ObjectTypeIds.sol";

contract InitPlayersSystem is System {
  function initPlayerObjectTypes() public {
    // Players
    ObjectTypeMetadata._set(
      PlayerObjectID,
      ObjectTypeMetadataData({
        isPlayer: true,
        isBlock: false,
        mass: 10,
        stackable: 0,
        durability: 0,
        damage: 0,
        hardness: 0
      })
    );
  }
}
