// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { MAX_PLAYER_ENERGY } from "../../Constants.sol";
import { PlayerObjectID } from "../../ObjectTypeIds.sol";

contract InitPlayersSystem is System {
  function initPlayerObjectTypes() public {
    // Players
    ObjectTypeMetadata._set(
      PlayerObjectID,
      ObjectTypeMetadataData({
        stackable: 0,
        maxInventorySlots: 36,
        mass: 10,
        energy: uint32(MAX_PLAYER_ENERGY),
        canPassThrough: false
      })
    );
  }
}
