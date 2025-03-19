// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { EntityId } from "@biomesaw/world/src/EntityId.sol";
import { EntityData } from "@biomesaw/world/src/Types.sol";

import { SmartItemMetadataData } from "./codegen/tables/SmartItemMetadata.sol";
import { GateApprovalsData } from "./codegen/tables/GateApprovals.sol";
import { ExchangeInfoData } from "./codegen/tables/ExchangeInfo.sol";
import { PipeAccessData } from "./codegen/tables/PipeAccess.sol";

struct ExchangeInfoDataWithExchangeId {
  bytes32 exchangeId;
  ExchangeInfoData exchangeInfoData;
}

struct PipeAccessDataWithEntityId {
  EntityId entityId;
  PipeAccessData pipeAccessData;
}

struct ExperienceEntityData {
  EntityData worldEntityData;
  address programAttacher;
  address programAdmin;
  SmartItemMetadataData smartItemMetadata;
  GateApprovalsData gateApprovalsData;
  ExchangeInfoDataWithExchangeId[] exchanges;
  PipeAccessDataWithEntityId[] pipeAccessDataList;
}
