// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { ObjectTypeSchema } from "../../codegen/tables/ObjectTypeSchema.sol";
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

    int32[] memory relativePositionsX = new int32[](1);
    int32[] memory relativePositionsY = new int32[](1);
    int32[] memory relativePositionsZ = new int32[](1);
    relativePositionsX[0] = 0;
    relativePositionsY[0] = 1;
    relativePositionsZ[0] = 0;

    ObjectTypeSchema._set(PlayerObjectID, relativePositionsX, relativePositionsY, relativePositionsZ);
  }
}
