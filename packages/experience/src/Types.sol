// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { BlockEntityData, BlockEntityDataWithOrientation } from "@biomesaw/world/src/Types.sol";

import { ItemShopData } from "./codegen/tables/ItemShop.sol";
import { ChestMetadataData } from "./codegen/tables/ChestMetadata.sol";
import { FFMetadataData } from "./codegen/tables/FFMetadata.sol";
import { ForceFieldApprovalsData } from "./codegen/tables/ForceFieldApprovals.sol";

struct BlockExperienceEntityData {
  BlockEntityData worldEntityData;
  address chipAttacher;
  ChestMetadataData chestMetadata;
  ItemShopData itemShopData;
  FFMetadataData ffMetadata;
  ForceFieldApprovalsData forceFieldApprovalsData;
}

struct BlockExperienceEntityDataWithOrientation {
  BlockEntityDataWithOrientation worldEntityData;
  address chipAttacher;
  ChestMetadataData chestMetadata;
  ItemShopData itemShopData;
  FFMetadataData ffMetadata;
  ForceFieldApprovalsData forceFieldApprovalsData;
}
