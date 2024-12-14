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
import { GateApprovals, GateApprovalsData } from "../codegen/tables/GateApprovals.sol";
import { ExchangeInfo, ExchangeInfoData } from "../codegen/tables/ExchangeInfo.sol";
import { Exchanges } from "../codegen/tables/Exchanges.sol";
import { BlockExperienceEntityData, BlockExperienceEntityDataWithGateApprovals, BlockExperienceEntityDataWithExchanges } from "../Types.sol";

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

  function getBlockEntityDataWithGateApprovals(
    bytes32 entityId
  ) public view returns (BlockExperienceEntityDataWithGateApprovals memory) {
    BlockEntityData memory blockEntityData = IWorld(_world()).getBlockEntityData(entityId);

    return
      BlockExperienceEntityDataWithGateApprovals({
        worldEntityData: blockEntityData,
        chipAttacher: ChipAttachment.get(entityId),
        chestMetadata: ChestMetadata.get(entityId),
        itemShopData: ItemShop.get(entityId),
        ffMetadata: FFMetadata.get(entityId),
        forceFieldApprovalsData: ForceFieldApprovals.get(entityId),
        gateApprovalsData: GateApprovals.get(entityId)
      });
  }

  function getBlockEntityDataWithExchanges(
    bytes32 entityId
  ) public view returns (BlockExperienceEntityDataWithExchanges memory) {
    BlockEntityData memory blockEntityData = IWorld(_world()).getBlockEntityData(entityId);
    bytes32[] memory exchangeIds = Exchanges.get(entityId);
    ExchangeInfoData[] memory exchangeInfoData = new ExchangeInfoData[](exchangeIds.length);
    for (uint256 i = 0; i < exchangeIds.length; i++) {
      exchangeInfoData[i] = ExchangeInfo.get(entityId, exchangeIds[i]);
    }

    return
      BlockExperienceEntityDataWithExchanges({
        worldEntityData: blockEntityData,
        chipAttacher: ChipAttachment.get(entityId),
        chestMetadata: ChestMetadata.get(entityId),
        ffMetadata: FFMetadata.get(entityId),
        forceFieldApprovalsData: ForceFieldApprovals.get(entityId),
        gateApprovalsData: GateApprovals.get(entityId),
        exchanges: exchangeInfoData
      });
  }

  function getBlocksEntityData(bytes32[] memory entityIds) public view returns (BlockExperienceEntityData[] memory) {
    BlockExperienceEntityData[] memory blockExperienceEntityData = new BlockExperienceEntityData[](entityIds.length);
    for (uint256 i = 0; i < entityIds.length; i++) {
      blockExperienceEntityData[i] = getBlockEntityData(entityIds[i]);
    }
    return blockExperienceEntityData;
  }

  function getBlocksEntityDataWithGateApprovals(
    bytes32[] memory entityIds
  ) public view returns (BlockExperienceEntityDataWithGateApprovals[] memory) {
    BlockExperienceEntityDataWithGateApprovals[]
      memory blockExperienceEntityData = new BlockExperienceEntityDataWithGateApprovals[](entityIds.length);
    for (uint256 i = 0; i < entityIds.length; i++) {
      blockExperienceEntityData[i] = getBlockEntityDataWithGateApprovals(entityIds[i]);
    }
    return blockExperienceEntityData;
  }

  function getBlocksEntityDataWithExchanges(
    bytes32[] memory entityIds
  ) public view returns (BlockExperienceEntityDataWithExchanges[] memory) {
    BlockExperienceEntityDataWithExchanges[]
      memory blockExperienceEntityData = new BlockExperienceEntityDataWithExchanges[](entityIds.length);
    for (uint256 i = 0; i < entityIds.length; i++) {
      blockExperienceEntityData[i] = getBlockEntityDataWithExchanges(entityIds[i]);
    }
    return blockExperienceEntityData;
  }
}
