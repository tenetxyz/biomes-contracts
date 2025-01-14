// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { BlockEntityData } from "@biomesaw/world/src/Types.sol";

import { ItemShopData } from "./codegen/tables/ItemShop.sol";
import { ChestMetadataData } from "./codegen/tables/ChestMetadata.sol";
import { FFMetadataData } from "./codegen/tables/FFMetadata.sol";
import { SmartItemMetadataData } from "./codegen/tables/SmartItemMetadata.sol";
import { ForceFieldApprovalsData } from "./codegen/tables/ForceFieldApprovals.sol";
import { GateApprovalsData } from "./codegen/tables/GateApprovals.sol";
import { ExchangeInfoData } from "./codegen/tables/ExchangeInfo.sol";
import { PipeAccessData } from "./codegen/tables/PipeAccess.sol";

struct ExchangeInfoDataWithExchangeId {
  bytes32 exchangeId;
  ExchangeInfoData exchangeInfoData;
}

struct BlockExperienceEntityData {
  BlockEntityData worldEntityData;
  address chipAttacher;
  ChestMetadataData chestMetadata;
  ItemShopData itemShopData;
  FFMetadataData ffMetadata;
  ForceFieldApprovalsData forceFieldApprovalsData;
}

struct BlockExperienceEntityDataWithGateApprovals {
  BlockEntityData worldEntityData;
  address chipAttacher;
  ChestMetadataData chestMetadata;
  ItemShopData itemShopData;
  FFMetadataData ffMetadata;
  ForceFieldApprovalsData forceFieldApprovalsData;
  GateApprovalsData gateApprovalsData;
}

struct BlockExperienceEntityDataWithExchanges {
  BlockEntityData worldEntityData;
  address chipAttacher;
  address chipAdmin;
  SmartItemMetadataData smartItemMetadata;
  GateApprovalsData gateApprovalsData;
  ExchangeInfoDataWithExchangeId[] exchanges;
}

struct PipeAccessDataWithEntityId {
  bytes32 entityId;
  PipeAccessData pipeAccessData;
}

struct BlockExperienceEntityDataWithPipeControls {
  BlockEntityData worldEntityData;
  address chipAttacher;
  address chipAdmin;
  SmartItemMetadataData smartItemMetadata;
  GateApprovalsData gateApprovalsData;
  ExchangeInfoDataWithExchangeId[] exchanges;
  PipeAccessDataWithEntityId[] pipeAccessDataList;
  bytes32[] enabledEntityIdsForPipeRouting;
}
