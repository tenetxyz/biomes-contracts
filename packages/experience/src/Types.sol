// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { BlockEntityData } from "@biomesaw/world/src/Types.sol";

import { SmartItemMetadataData } from "./codegen/tables/SmartItemMetadata.sol";
import { GateApprovalsData } from "./codegen/tables/GateApprovals.sol";
import { ExchangeInfoData } from "./codegen/tables/ExchangeInfo.sol";
import { PipeAccessData } from "./codegen/tables/PipeAccess.sol";

struct ExchangeInfoDataWithExchangeId {
  bytes32 exchangeId;
  ExchangeInfoData exchangeInfoData;
}

struct PipeAccessDataWithEntityId {
  bytes32 entityId;
  PipeAccessData pipeAccessData;
}

struct BlockExperienceEntityData {
  BlockEntityData worldEntityData;
  address chipAttacher;
  address chipAdmin;
  SmartItemMetadataData smartItemMetadata;
  GateApprovalsData gateApprovalsData;
  ExchangeInfoDataWithExchangeId[] exchanges;
  PipeAccessDataWithEntityId[] pipeAccessDataList;
}
