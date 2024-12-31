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
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { Assets } from "../src/codegen/tables/Assets.sol";
import { ResourceType } from "../src/codegen/common.sol";
import { Exchanges } from "../src/codegen/tables/Exchanges.sol";
import { ExchangeInfo, ExchangeInfoData } from "../src/codegen/tables/ExchangeInfo.sol";
import { encodeAddressExchangeResourceId, encodeObjectExchangeResourceId } from "../src/utils/ExchangeUtils.sol";

import { numMaxInChest, getCount } from "../src/utils/EntityUtils.sol";
import { ExchangeInfoDataWithExchangeId } from "../src/Types.sol";
import { SakuraLogObjectID, StoneObjectID } from "@biomesaw/world/src/ObjectTypeIds.sol";

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

    bytes32 chestEntityId = 0x0000000000000000000000000000000000000000000000000000000000258775;
    ExchangeInfo.set(
      chestEntityId,
      BUY_EXCHANGE_ID,
      ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(StoneObjectID),
        inUnitAmount: 5,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.ERC721,
        outResourceId: encodeAddressExchangeResourceId(0x4e77442A934D997E8121B741Af39419e75EF9282),
        outUnitAmount: 1,
        outMaxAmount: type(uint256).max
      })
    );

    Exchanges.push(chestEntityId, BUY_EXCHANGE_ID);
    Chip.setChipAddress(chestEntityId, 0x39EA498e5907F6fA25E11dd50f0bc423B1F03E49);

    vm.stopBroadcast();
  }
}
