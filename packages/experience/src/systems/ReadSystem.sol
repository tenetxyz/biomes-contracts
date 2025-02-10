// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "@biomesaw/world/src/codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { BlockEntityData } from "@biomesaw/world/src/Types.sol";

import { ChipAttachment } from "../codegen/tables/ChipAttachment.sol";
import { ChipAdmin } from "../codegen/tables/ChipAdmin.sol";
import { SmartItemMetadata, SmartItemMetadataData } from "../codegen/tables/SmartItemMetadata.sol";
import { GateApprovals, GateApprovalsData } from "../codegen/tables/GateApprovals.sol";
import { ExchangeInfo, ExchangeInfoData } from "../codegen/tables/ExchangeInfo.sol";
import { Exchanges } from "../codegen/tables/Exchanges.sol";
import { PipeAccess } from "../codegen/tables/PipeAccess.sol";
import { PipeAccessList } from "../codegen/tables/PipeAccessList.sol";
import { BlockExperienceEntityData, PipeAccessDataWithEntityId, ExchangeInfoDataWithExchangeId } from "../Types.sol";

contract ReadSystem is System {
  function getBlockEntityData(bytes32 entityId) public view returns (BlockExperienceEntityData memory) {
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
    PipeAccessDataWithEntityId[] memory pipeAccessDataList = new PipeAccessDataWithEntityId[](
      approvedEntityIdsForPipeTransfer.length
    );
    for (uint256 i = 0; i < approvedEntityIdsForPipeTransfer.length; i++) {
      pipeAccessDataList[i] = PipeAccessDataWithEntityId({
        entityId: approvedEntityIdsForPipeTransfer[i],
        pipeAccessData: PipeAccess.get(entityId, approvedEntityIdsForPipeTransfer[i])
      });
    }

    return
      BlockExperienceEntityData({
        worldEntityData: blockEntityData,
        chipAttacher: ChipAttachment.get(entityId),
        chipAdmin: ChipAdmin.get(entityId),
        smartItemMetadata: SmartItemMetadata.get(entityId),
        gateApprovalsData: GateApprovals.get(entityId),
        exchanges: exchangeInfoData,
        pipeAccessDataList: pipeAccessDataList
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
