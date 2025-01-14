// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "@biomesaw/world/src/codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { BlockEntityData } from "@biomesaw/world/src/Types.sol";

import { ChipAttachment } from "../codegen/tables/ChipAttachment.sol";
import { ChipAdmin } from "../codegen/tables/ChipAdmin.sol";
import { ItemShop, ItemShopData } from "../codegen/tables/ItemShop.sol";
import { ChestMetadata, ChestMetadata } from "../codegen/tables/ChestMetadata.sol";
import { FFMetadata } from "../codegen/tables/FFMetadata.sol";
import { ForceFieldApprovals, ForceFieldApprovalsData } from "../codegen/tables/ForceFieldApprovals.sol";
import { SmartItemMetadata, SmartItemMetadataData } from "../codegen/tables/SmartItemMetadata.sol";
import { GateApprovals, GateApprovalsData } from "../codegen/tables/GateApprovals.sol";
import { ExchangeInfo, ExchangeInfoData } from "../codegen/tables/ExchangeInfo.sol";
import { Exchanges } from "../codegen/tables/Exchanges.sol";
import { PipeAccess } from "../codegen/tables/PipeAccess.sol";
import { PipeRouting } from "../codegen/tables/PipeRouting.sol";
import { PipeAccessList } from "../codegen/tables/PipeAccessList.sol";
import { PipeRoutingList } from "../codegen/tables/PipeRoutingList.sol";
import { BlockExperienceEntityData, BlockExperienceEntityDataWithGateApprovals, BlockExperienceEntityDataWithExchanges, ExchangeInfoDataWithExchangeId, BlockExperienceEntityDataWithPipeControls, PipeAccessDataWithEntityId } from "../Types.sol";

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
    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData = new ExchangeInfoDataWithExchangeId[](exchangeIds.length);
    for (uint256 i = 0; i < exchangeIds.length; i++) {
      exchangeInfoData[i] = ExchangeInfoDataWithExchangeId({
        exchangeId: exchangeIds[i],
        exchangeInfoData: ExchangeInfo.get(entityId, exchangeIds[i])
      });
    }

    return
      BlockExperienceEntityDataWithExchanges({
        worldEntityData: blockEntityData,
        chipAttacher: ChipAttachment.get(entityId),
        chipAdmin: ChipAdmin.get(entityId),
        smartItemMetadata: SmartItemMetadata.get(entityId),
        gateApprovalsData: GateApprovals.get(entityId),
        exchanges: exchangeInfoData
      });
  }

  function getBlockEntityDataWithPipeControls(
    bytes32 entityId
  ) public view returns (BlockExperienceEntityDataWithPipeControls memory) {
    BlockEntityData memory blockEntityData = IWorld(_world()).getBlockEntityData(entityId);
    bytes32[] memory exchangeIds = Exchanges.get(entityId);
    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData = new ExchangeInfoDataWithExchangeId[](exchangeIds.length);
    for (uint256 i = 0; i < exchangeIds.length; i++) {
      exchangeInfoData[i] = ExchangeInfoDataWithExchangeId({
        exchangeId: exchangeIds[i],
        exchangeInfoData: ExchangeInfo.get(entityId, exchangeIds[i])
      });
    }
    bytes32[] memory approvedEntityIdsForPipeTransfer = PipeAccessList.get(entityId);
    PipeAccessDataWithEntityId[] memory pipeAccessData = new PipeAccessDataWithEntityId[](
      approvedEntityIdsForPipeTransfer.length
    );
    for (uint256 i = 0; i < approvedEntityIdsForPipeTransfer.length; i++) {
      pipeAccessData[i] = PipeAccessDataWithEntityId({
        entityId: approvedEntityIdsForPipeTransfer[i],
        pipeAccessData: PipeAccess.get(entityId, approvedEntityIdsForPipeTransfer[i])
      });
    }

    return
      BlockExperienceEntityDataWithPipeControls({
        worldEntityData: blockEntityData,
        chipAttacher: ChipAttachment.get(entityId),
        chipAdmin: ChipAdmin.get(entityId),
        smartItemMetadata: SmartItemMetadata.get(entityId),
        gateApprovalsData: GateApprovals.get(entityId),
        exchanges: exchangeInfoData,
        pipeAccessData: pipeAccessData,
        enabledEntityIdsForPipeRouting: PipeRoutingList.get(entityId)
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

  function getBlocksEntityDataWithPipeControls(
    bytes32[] memory entityIds
  ) public view returns (BlockExperienceEntityDataWithPipeControls[] memory) {
    BlockExperienceEntityDataWithPipeControls[]
      memory blockExperienceEntityData = new BlockExperienceEntityDataWithPipeControls[](entityIds.length);
    for (uint256 i = 0; i < entityIds.length; i++) {
      blockExperienceEntityData[i] = getBlockEntityDataWithPipeControls(entityIds[i]);
    }
    return blockExperienceEntityData;
  }
}
