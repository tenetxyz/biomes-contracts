// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { AirObjectID } from "../../ObjectTypeIds.sol";

contract InitBlocksSystem is System {
  function initBlockObjectTypes() public {
    ObjectTypeMetadata.set(
      AirObjectID,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: true,
        mass: 0,
        stackable: 0,
        durability: 0,
        damage: 0,
        occurence: IWorld(_world()).getTerrainBlock.selector
      })
    );
  }

  function initBlockRecipes() public {}
}
