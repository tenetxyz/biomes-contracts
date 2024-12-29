// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";

import { ChipMetadata, ChipMetadataData } from "../src/codegen/tables/ChipMetadata.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { Tokens } from "../src/codegen/tables/Tokens.sol";
import { NFTs } from "../src/codegen/tables/NFTs.sol";
import { ERC20Metadata } from "../src/codegen/tables/ERC20Metadata.sol";
import { ERC721Metadata } from "../src/codegen/tables/ERC721Metadata.sol";
import { ItemShop } from "../src/codegen/tables/ItemShop.sol";
import { ChipAttachment } from "../src/codegen/tables/ChipAttachment.sol";
import { ChipAdmin } from "../src/codegen/tables/ChipAdmin.sol";
import { ForceFieldApprovals } from "../src/codegen/tables/ForceFieldApprovals.sol";
import { GateApprovals, GateApprovalsData } from "../src/codegen/tables/GateApprovals.sol";
import { SmartItemMetadata, SmartItemMetadataData } from "../src/codegen/tables/SmartItemMetadata.sol";
import { Chip } from "@biomesaw/world/src/codegen/tables/Chip.sol";
import { NamespaceId } from "../src/codegen/tables/NamespaceId.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { Assets } from "../src/codegen/tables/Assets.sol";
import { ResourceType } from "../src/codegen/common.sol";
import { Exchanges } from "../src/codegen/tables/Exchanges.sol";
import { ExchangeInfo, ExchangeInfoData } from "../src/codegen/tables/ExchangeInfo.sol";
import { encodeAddressExchangeResourceId, encodeObjectExchangeResourceId } from "../src/utils/ExchangeUtils.sol";

import { numMaxInChest, getCount } from "../src/utils/EntityUtils.sol";
import { ExchangeInfoDataWithExchangeId } from "../src/Types.sol";

bytes32 constant BUY_EXCHANGE_ID = bytes32("buy");
bytes32 constant SELL_EXCHANGE_ID = bytes32("sell");

struct ExchangeInfoDataWithEntityId {
  bytes32 entityId;
  ExchangeInfoDataWithExchangeId[] exchangeInfoData;
}

contract Upgrade is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    // console.logUint(ItemShop.getBalance(0x000000000000000000000000000000000000000000000000000000000002ec2d));
    // console.log(ItemShop.getPaymentToken(0x000000000000000000000000000000000000000000000000000000000002ec2d));
    // ItemShop.setBalance(0x000000000000000000000000000000000000000000000000000000000002ec2d, type(uint256).max);

    ExchangeInfoDataWithEntityId[] memory allExchangeInfos = new ExchangeInfoDataWithEntityId[](2);
    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData0 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData0[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(97),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(97) -
          getCount(0x000000000000000000000000000000000000000000000000000000000000577f, 97),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 24000000000000000000
      })
    });
    exchangeInfoData0[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(97),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000000577f, 97) - 1
      })
    });

    allExchangeInfos[0] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000000577f,
      exchangeInfoData: exchangeInfoData0
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData1 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData1[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(50),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(50) -
          getCount(0x0000000000000000000000000000000000000000000000000000000000008b46, 50),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 30000000000000000000
      })
    });
    exchangeInfoData1[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(50),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x0000000000000000000000000000000000000000000000000000000000008b46, 50) - 1
      })
    });

    allExchangeInfos[1] = ExchangeInfoDataWithEntityId({
      entityId: 0x0000000000000000000000000000000000000000000000000000000000008b46,
      exchangeInfoData: exchangeInfoData1
    });

    for (uint i = 0; i < allExchangeInfos.length; i++) {
      ExchangeInfoDataWithEntityId memory exchangeInfo = allExchangeInfos[i];
      bytes32[] memory exchangeIds = new bytes32[](exchangeInfo.exchangeInfoData.length);
      for (uint j = 0; j < exchangeInfo.exchangeInfoData.length; j++) {
        ExchangeInfoDataWithExchangeId memory exchangeInfoData = exchangeInfo.exchangeInfoData[j];
        ExchangeInfo.set(exchangeInfo.entityId, exchangeInfoData.exchangeId, exchangeInfoData.exchangeInfoData);
        exchangeIds[j] = exchangeInfoData.exchangeId;
      }
      Exchanges.set(exchangeInfo.entityId, exchangeIds);
    }

    vm.stopBroadcast();
  }
}
