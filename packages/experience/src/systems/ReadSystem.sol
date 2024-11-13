// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "@biomesaw/world/src/codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { BlockEntityData } from "@biomesaw/world/src/Types.sol";

import { ChipAttachment } from "../codegen/tables/ChipAttachment.sol";
import { ItemShop, ItemShopData } from "../codegen/tables/ItemShop.sol";
import { ChestMetadata, ChestMetadata } from "../codegen/tables/ChestMetadata.sol";
import { FFMetadata } from "../codegen/tables/FFMetadata.sol";
import { ForceFieldApprovals, ForceFieldApprovalsData } from "../codegen/tables/ForceFieldApprovals.sol";

import { BlockExperienceEntityData } from "../Types.sol";

contract ReadSystem is System {
  function getBlockEntityData(bytes32 entityId) public view returns (BlockExperienceEntityData memory) {
    BlockEntityData memory blockEntityData = IWorld(_world()).getBlockEntityData(entityId);

    return
      BlockExperienceEntityData({
        worldEntityData: blockEntityData,
        chipAttacher: ChipAttachment.get(entityId),
        chestMetadata: ChestMetadata.get(entityId),
        itemShopData: ItemShop.get(entityId),
        ffMetadata: FFMetadata.get(entityId),
        forceFieldApprovalsData: ForceFieldApprovals.get(entityId)
      });
  }

  function getBlocksEntityData(bytes32[] memory entityIds) public view returns (BlockExperienceEntityData[] memory) {
    BlockExperienceEntityData[] memory blockExperienceEntityData = new BlockExperienceEntityData[](entityIds.length);
    for (uint256 i = 0; i < entityIds.length; i++) {
      blockExperienceEntityData[i] = getBlockEntityData(entityIds[i]);
    }
    return blockExperienceEntityData;
  }
}
