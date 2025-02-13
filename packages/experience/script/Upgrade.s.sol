// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";

import { Chip } from "@biomesaw/world/src/codegen/tables/Chip.sol";
import { EntityId } from "@biomesaw/world/src/EntityId.sol";
import { SakuraLogObjectID, StoneObjectID } from "@biomesaw/world/src/ObjectTypeIds.sol";

import { ChipMetadata, ChipMetadataData } from "../src/codegen/tables/ChipMetadata.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { ChipAttachment } from "../src/codegen/tables/ChipAttachment.sol";
import { ChipAdmin } from "../src/codegen/tables/ChipAdmin.sol";
import { GateApprovals, GateApprovalsData } from "../src/codegen/tables/GateApprovals.sol";
import { SmartItemMetadata, SmartItemMetadataData } from "../src/codegen/tables/SmartItemMetadata.sol";
import { ResourceType } from "../src/codegen/common.sol";
import { Exchanges } from "../src/codegen/tables/Exchanges.sol";
import { ExchangeInfo, ExchangeInfoData } from "../src/codegen/tables/ExchangeInfo.sol";
import { encodeAddressExchangeResourceId, encodeObjectExchangeResourceId } from "../src/utils/ExchangeUtils.sol";

bytes32 constant BUY_EXCHANGE_ID = bytes32("buy");
bytes32 constant SELL_EXCHANGE_ID = bytes32("sell");

contract Upgrade is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    EntityId chestEntityId = EntityId.wrap(0x0000000000000000000000000000000000000000000000000000000000258775);
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
    // TODO: use chip system id
    // Chip.setChipAddress(chestEntityId, 0x39EA498e5907F6fA25E11dd50f0bc423B1F03E49);

    vm.stopBroadcast();
  }
}
