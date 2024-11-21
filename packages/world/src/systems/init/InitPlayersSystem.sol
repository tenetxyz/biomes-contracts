// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { ObjectTypeSchema, ObjectTypeSchemaData } from "../../codegen/tables/ObjectTypeSchema.sol";

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

    int16[] memory relativePositionsX = new int16[](1);
    int16[] memory relativePositionsY = new int16[](1);
    int16[] memory relativePositionsZ = new int16[](1);
    relativePositionsX[0] = 0;
    relativePositionsY[0] = 1;
    relativePositionsZ[0] = 0;

    ObjectTypeSchema._set(PlayerObjectID, relativePositionsX, relativePositionsY, relativePositionsZ);
  }
}
