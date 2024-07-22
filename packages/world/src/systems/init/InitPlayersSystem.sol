// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { PlayerObjectID } from "../../ObjectTypeIds.sol";

contract InitPlayersSystem is System {
  function initPlayerObjectTypes() public {
    // Players
    ObjectTypeMetadata._set(
      PlayerObjectID,
      ObjectTypeMetadataData({
        isBlock: false,
        isTool: false,
        miningDifficulty: 0,
        stackable: 0,
        durability: 0,
        damage: 0
      })
    );
  }
}
