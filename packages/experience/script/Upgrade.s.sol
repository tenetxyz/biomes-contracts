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

    ExchangeInfoDataWithEntityId[] memory allExchangeInfos = new ExchangeInfoDataWithEntityId[](84);
    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData0 = new ExchangeInfoDataWithExchangeId[](1);
    exchangeInfoData0[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(50),
        inUnitAmount: 1,
        inMaxAmount: 1188,
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 1000000000000000000,
        outMaxAmount: 1188000000000000000000
      })
    });

    allExchangeInfos[0] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000002ec2e,
      exchangeInfoData: exchangeInfoData0
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData1 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData1[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(119),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(119) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004d5fd, 119),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 594000000000000000000
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
        outResourceId: encodeObjectExchangeResourceId(119),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004d5fd, 119) - 1
      })
    });

    allExchangeInfos[1] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004d5fd,
      exchangeInfoData: exchangeInfoData1
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData2 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData2[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(121),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(121) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004d5fe, 121),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 222750000000000000000
      })
    });
    exchangeInfoData2[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(121),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004d5fe, 121) - 1
      })
    });

    allExchangeInfos[2] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004d5fe,
      exchangeInfoData: exchangeInfoData2
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData3 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData3[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(120),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(120) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004d5ff, 120),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 148500000000000000000
      })
    });
    exchangeInfoData3[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(120),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004d5ff, 120) - 1
      })
    });

    allExchangeInfos[3] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004d5ff,
      exchangeInfoData: exchangeInfoData3
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData4 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData4[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(118),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(118) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004d600, 118),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 640937329700272479564
      })
    });
    exchangeInfoData4[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(118),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004d600, 118) - 1
      })
    });

    allExchangeInfos[4] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004d600,
      exchangeInfoData: exchangeInfoData4
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData5 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData5[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(110),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(110) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004d605, 110),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 891000000000000000000
      })
    });
    exchangeInfoData5[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(110),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004d605, 110) - 1
      })
    });

    allExchangeInfos[5] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004d605,
      exchangeInfoData: exchangeInfoData5
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData6 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData6[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(43),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(43) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004d60a, 43),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 2821500000000000000000
      })
    });
    exchangeInfoData6[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(43),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004d60a, 43) - 1
      })
    });

    allExchangeInfos[6] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004d60a,
      exchangeInfoData: exchangeInfoData6
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData7 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData7[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(81),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(81) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004d60b, 81),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 3415500000000000000000
      })
    });
    exchangeInfoData7[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(81),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004d60b, 81) - 1
      })
    });

    allExchangeInfos[7] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004d60b,
      exchangeInfoData: exchangeInfoData7
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData8 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData8[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(80),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(80) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004d60c, 80),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 3267000000000000000000
      })
    });
    exchangeInfoData8[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(80),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004d60c, 80) - 1
      })
    });

    allExchangeInfos[8] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004d60c,
      exchangeInfoData: exchangeInfoData8
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData9 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData9[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(99),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(99) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004d60d, 99),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 2238807106598984771573
      })
    });
    exchangeInfoData9[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(99),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004d60d, 99) - 1
      })
    });

    allExchangeInfos[9] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004d60d,
      exchangeInfoData: exchangeInfoData9
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData10 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData10[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(26),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(26) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004d613, 26),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 2153250000000000000000
      })
    });
    exchangeInfoData10[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(26),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004d613, 26) - 1
      })
    });

    allExchangeInfos[10] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004d613,
      exchangeInfoData: exchangeInfoData10
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData11 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData11[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(82),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(82) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004d614, 82),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 3564000000000000000000
      })
    });
    exchangeInfoData11[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(82),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004d614, 82) - 1
      })
    });

    allExchangeInfos[11] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004d614,
      exchangeInfoData: exchangeInfoData11
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData12 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData12[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(104),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(104) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004d615, 104),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 2233139240506329113924
      })
    });
    exchangeInfoData12[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(104),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004d615, 104) - 1
      })
    });

    allExchangeInfos[12] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004d615,
      exchangeInfoData: exchangeInfoData12
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData13 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData13[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(107),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(107) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004d616, 107),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 2281267241379310344827
      })
    });
    exchangeInfoData13[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(107),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004d616, 107) - 1
      })
    });

    allExchangeInfos[13] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004d616,
      exchangeInfoData: exchangeInfoData13
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData14 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData14[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(25),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(25) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004d61b, 25),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 2227500000000000000000
      })
    });
    exchangeInfoData14[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(25),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004d61b, 25) - 1
      })
    });

    allExchangeInfos[14] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004d61b,
      exchangeInfoData: exchangeInfoData14
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData15 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData15[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(24),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(24) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004d620, 24),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 2301750000000000000000
      })
    });
    exchangeInfoData15[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(24),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004d620, 24) - 1
      })
    });

    allExchangeInfos[15] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004d620,
      exchangeInfoData: exchangeInfoData15
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData16 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData16[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(21),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(21) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004d621, 21),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 2301750000000000000000
      })
    });
    exchangeInfoData16[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(21),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004d621, 21) - 1
      })
    });

    allExchangeInfos[16] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004d621,
      exchangeInfoData: exchangeInfoData16
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData17 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData17[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(23),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(23) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004d622, 23),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 2380006745362563237774
      })
    });
    exchangeInfoData17[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(23),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004d622, 23) - 1
      })
    });

    allExchangeInfos[17] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004d622,
      exchangeInfoData: exchangeInfoData17
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData18 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData18[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(32),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(32) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004d623, 32),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 2736410583941605839416
      })
    });
    exchangeInfoData18[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(32),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004d623, 32) - 1
      })
    });

    allExchangeInfos[18] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004d623,
      exchangeInfoData: exchangeInfoData18
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData19 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData19[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(117),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(117) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddab, 117),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 594000000000000000000
      })
    });
    exchangeInfoData19[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(117),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddab, 117) - 1
      })
    });

    allExchangeInfos[19] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddab,
      exchangeInfoData: exchangeInfoData19
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData20 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData20[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(114),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(114) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddac, 114),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 594000000000000000000
      })
    });
    exchangeInfoData20[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(114),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddac, 114) - 1
      })
    });

    allExchangeInfos[20] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddac,
      exchangeInfoData: exchangeInfoData20
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData21 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData21[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(113),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(113) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddad, 113),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 594000000000000000000
      })
    });
    exchangeInfoData21[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(113),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddad, 113) - 1
      })
    });

    allExchangeInfos[21] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddad,
      exchangeInfoData: exchangeInfoData21
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData22 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData22[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(123),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(123) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddaf, 123),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 222937657961246840775
      })
    });
    exchangeInfoData22[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(123),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddaf, 123) - 1
      })
    });

    allExchangeInfos[22] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddaf,
      exchangeInfoData: exchangeInfoData22
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData23 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData23[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(122),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(122) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddb0, 122),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 242332417582417582417
      })
    });
    exchangeInfoData23[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(122),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddb0, 122) - 1
      })
    });

    allExchangeInfos[23] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddb0,
      exchangeInfoData: exchangeInfoData23
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData24 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData24[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(111),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(111) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddb1, 111),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 594000000000000000000
      })
    });
    exchangeInfoData24[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(111),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddb1, 111) - 1
      })
    });

    allExchangeInfos[24] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddb1,
      exchangeInfoData: exchangeInfoData24
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData25 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData25[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(115),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(115) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddb6, 115),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 1612595978062157221206
      })
    });
    exchangeInfoData25[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(115),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddb6, 115) - 1
      })
    });

    allExchangeInfos[25] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddb6,
      exchangeInfoData: exchangeInfoData25
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData26 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData26[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(100),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(100) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddbb, 100),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 5037120000000000000000
      })
    });
    exchangeInfoData26[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(100),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddbb, 100) - 1
      })
    });

    allExchangeInfos[26] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddbb,
      exchangeInfoData: exchangeInfoData26
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData27 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData27[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(97),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(97) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddbc, 97),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 1490016891891891891891
      })
    });
    exchangeInfoData27[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(97),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddbc, 97) - 1
      })
    });

    allExchangeInfos[27] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddbc,
      exchangeInfoData: exchangeInfoData27
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData28 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData28[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(89),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(89) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddbe, 89),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 7959600000000000000000
      })
    });
    exchangeInfoData28[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(89),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddbe, 89) - 1
      })
    });

    allExchangeInfos[28] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddbe,
      exchangeInfoData: exchangeInfoData28
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData29 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData29[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(109),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(109) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddc0, 109),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 4793967391304347826086
      })
    });
    exchangeInfoData29[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(109),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddc0, 109) - 1
      })
    });

    allExchangeInfos[29] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddc0,
      exchangeInfoData: exchangeInfoData29
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData30 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData30[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(102),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(102) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddc5, 102),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 4927230000000000000000
      })
    });
    exchangeInfoData30[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(102),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddc5, 102) - 1
      })
    });

    allExchangeInfos[30] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddc5,
      exchangeInfoData: exchangeInfoData30
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData31 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData31[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(105),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(105) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddc6, 105),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 4850010000000000000000
      })
    });
    exchangeInfoData31[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(105),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddc6, 105) - 1
      })
    });

    allExchangeInfos[31] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddc6,
      exchangeInfoData: exchangeInfoData31
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData32 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData32[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(88),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(88) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddc7, 88),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 7591320000000000000000
      })
    });
    exchangeInfoData32[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(88),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddc7, 88) - 1
      })
    });

    allExchangeInfos[32] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddc7,
      exchangeInfoData: exchangeInfoData32
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData33 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData33[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(93),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(93) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddc8, 93),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 18458550000000000000000
      })
    });
    exchangeInfoData33[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(93),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddc8, 93) - 1
      })
    });

    allExchangeInfos[33] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddc8,
      exchangeInfoData: exchangeInfoData33
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData34 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData34[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(44),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(44) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddc9, 44),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 7425000000000000000000
      })
    });
    exchangeInfoData34[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(44),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddc9, 44) - 1
      })
    });

    allExchangeInfos[34] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddc9,
      exchangeInfoData: exchangeInfoData34
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData35 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData35[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(108),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(108) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddca, 108),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 3118500000000000000000
      })
    });
    exchangeInfoData35[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(108),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddca, 108) - 1
      })
    });

    allExchangeInfos[35] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddca,
      exchangeInfoData: exchangeInfoData35
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData36 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData36[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(30),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(30) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddcf, 30),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 2079000000000000000000
      })
    });
    exchangeInfoData36[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(30),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddcf, 30) - 1
      })
    });

    allExchangeInfos[36] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddcf,
      exchangeInfoData: exchangeInfoData36
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData37 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData37[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(22),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(22) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddd4, 22),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 2273427835051546391752
      })
    });
    exchangeInfoData37[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(22),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddd4, 22) - 1
      })
    });

    allExchangeInfos[37] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddd4,
      exchangeInfoData: exchangeInfoData37
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData38 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData38[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(29),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(29) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddd5, 29),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 2227500000000000000000
      })
    });
    exchangeInfoData38[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(29),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddd5, 29) - 1
      })
    });

    allExchangeInfos[38] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddd5,
      exchangeInfoData: exchangeInfoData38
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData39 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData39[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(27),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(27) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddd6, 27),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 2301750000000000000000
      })
    });
    exchangeInfoData39[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(27),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddd6, 27) - 1
      })
    });

    allExchangeInfos[39] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddd6,
      exchangeInfoData: exchangeInfoData39
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData40 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData40[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(31),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(31) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddd7, 31),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 2153250000000000000000
      })
    });
    exchangeInfoData40[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(31),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddd7, 31) - 1
      })
    });

    allExchangeInfos[40] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddd7,
      exchangeInfoData: exchangeInfoData40
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData41 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData41[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(33),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(33) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddd8, 33),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 2376000000000000000000
      })
    });
    exchangeInfoData41[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(33),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddd8, 33) - 1
      })
    });

    allExchangeInfos[41] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddd8,
      exchangeInfoData: exchangeInfoData41
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData42 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData42[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(28),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(28) -
          getCount(0x000000000000000000000000000000000000000000000000000000000004ddd9, 28),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 2233139240506329113924
      })
    });
    exchangeInfoData42[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(28),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000004ddd9, 28) - 1
      })
    });

    allExchangeInfos[42] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000004ddd9,
      exchangeInfoData: exchangeInfoData42
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData43 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData43[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(72),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(72) -
          getCount(0x0000000000000000000000000000000000000000000000000000000000051632, 72),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 4761904761904761
      })
    });
    exchangeInfoData43[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(72),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x0000000000000000000000000000000000000000000000000000000000051632, 72) - 1
      })
    });

    allExchangeInfos[43] = ExchangeInfoDataWithEntityId({
      entityId: 0x0000000000000000000000000000000000000000000000000000000000051632,
      exchangeInfoData: exchangeInfoData43
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData44 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData44[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(112),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(112) -
          getCount(0x0000000000000000000000000000000000000000000000000000000000051aac, 112),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 594000000000000000000
      })
    });
    exchangeInfoData44[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(112),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x0000000000000000000000000000000000000000000000000000000000051aac, 112) - 1
      })
    });

    allExchangeInfos[44] = ExchangeInfoDataWithEntityId({
      entityId: 0x0000000000000000000000000000000000000000000000000000000000051aac,
      exchangeInfoData: exchangeInfoData44
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData45 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData45[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(91),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(91) -
          getCount(0x0000000000000000000000000000000000000000000000000000000000051ab5, 91),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 7425000000000000000000
      })
    });
    exchangeInfoData45[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(91),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x0000000000000000000000000000000000000000000000000000000000051ab5, 91) - 1
      })
    });

    allExchangeInfos[45] = ExchangeInfoDataWithEntityId({
      entityId: 0x0000000000000000000000000000000000000000000000000000000000051ab5,
      exchangeInfoData: exchangeInfoData45
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData46 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData46[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(95),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(95) -
          getCount(0x0000000000000000000000000000000000000000000000000000000000051abe, 95),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 76761566953528399311531
      })
    });
    exchangeInfoData46[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(95),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x0000000000000000000000000000000000000000000000000000000000051abe, 95) - 1
      })
    });

    allExchangeInfos[46] = ExchangeInfoDataWithEntityId({
      entityId: 0x0000000000000000000000000000000000000000000000000000000000051abe,
      exchangeInfoData: exchangeInfoData46
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData47 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData47[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(100),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(100) -
          getCount(0x00000000000000000000000000000000000000000000000000000000000529b1, 100),
        outResourceType: ResourceType.NativeCurrency,
        outResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        outUnitAmount: 0,
        outMaxAmount: 21902654867256637
      })
    });
    exchangeInfoData47[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.NativeCurrency,
        inResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(100),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x00000000000000000000000000000000000000000000000000000000000529b1, 100) - 1
      })
    });

    allExchangeInfos[47] = ExchangeInfoDataWithEntityId({
      entityId: 0x00000000000000000000000000000000000000000000000000000000000529b1,
      exchangeInfoData: exchangeInfoData47
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData48 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData48[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(93),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(93) -
          getCount(0x0000000000000000000000000000000000000000000000000000000000057a30, 93),
        outResourceType: ResourceType.NativeCurrency,
        outResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        outUnitAmount: 0,
        outMaxAmount: 16744186046511627
      })
    });
    exchangeInfoData48[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.NativeCurrency,
        inResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(93),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x0000000000000000000000000000000000000000000000000000000000057a30, 93) - 1
      })
    });

    allExchangeInfos[48] = ExchangeInfoDataWithEntityId({
      entityId: 0x0000000000000000000000000000000000000000000000000000000000057a30,
      exchangeInfoData: exchangeInfoData48
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData49 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData49[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(88),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(88) -
          getCount(0x0000000000000000000000000000000000000000000000000000000000064ed8, 88),
        outResourceType: ResourceType.NativeCurrency,
        outResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        outUnitAmount: 0,
        outMaxAmount: 9729729729729729
      })
    });
    exchangeInfoData49[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.NativeCurrency,
        inResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(88),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x0000000000000000000000000000000000000000000000000000000000064ed8, 88) - 1
      })
    });

    allExchangeInfos[49] = ExchangeInfoDataWithEntityId({
      entityId: 0x0000000000000000000000000000000000000000000000000000000000064ed8,
      exchangeInfoData: exchangeInfoData49
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData50 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData50[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(91),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(91) -
          getCount(0x000000000000000000000000000000000000000000000000000000000006b246, 91),
        outResourceType: ResourceType.NativeCurrency,
        outResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        outUnitAmount: 0,
        outMaxAmount: 3928571428571428
      })
    });
    exchangeInfoData50[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.NativeCurrency,
        inResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(91),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000006b246, 91) - 1
      })
    });

    allExchangeInfos[50] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000006b246,
      exchangeInfoData: exchangeInfoData50
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData51 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData51[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(165),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(165) -
          getCount(0x000000000000000000000000000000000000000000000000000000000006bac7, 165),
        outResourceType: ResourceType.NativeCurrency,
        outResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        outUnitAmount: 0,
        outMaxAmount: 38076923076923076
      })
    });
    exchangeInfoData51[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.NativeCurrency,
        inResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(165),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000006bac7, 165) - 1
      })
    });

    allExchangeInfos[51] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000006bac7,
      exchangeInfoData: exchangeInfoData51
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData52 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData52[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(71),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(71) -
          getCount(0x000000000000000000000000000000000000000000000000000000000008a395, 71),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 54545454545454545
      })
    });
    exchangeInfoData52[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(71),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000008a395, 71) - 1
      })
    });

    allExchangeInfos[52] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000008a395,
      exchangeInfoData: exchangeInfoData52
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData53 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData53[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(91),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(91) -
          getCount(0x000000000000000000000000000000000000000000000000000000000008b5f4, 91),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 11200000000000000000
      })
    });
    exchangeInfoData53[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(91),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000008b5f4, 91) - 1
      })
    });

    allExchangeInfos[53] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000008b5f4,
      exchangeInfoData: exchangeInfoData53
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData54 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData54[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(60),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(60) -
          getCount(0x000000000000000000000000000000000000000000000000000000000009e6ab, 60),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 11880000000000000000
      })
    });
    exchangeInfoData54[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(60),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000009e6ab, 60) - 1
      })
    });

    allExchangeInfos[54] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000009e6ab,
      exchangeInfoData: exchangeInfoData54
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData55 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData55[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(73),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(73) -
          getCount(0x00000000000000000000000000000000000000000000000000000000000da819, 73),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 9090909090909090
      })
    });
    exchangeInfoData55[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(73),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x00000000000000000000000000000000000000000000000000000000000da819, 73) - 1
      })
    });

    allExchangeInfos[55] = ExchangeInfoDataWithEntityId({
      entityId: 0x00000000000000000000000000000000000000000000000000000000000da819,
      exchangeInfoData: exchangeInfoData55
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData56 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData56[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(37),
        inUnitAmount: 1,
        inMaxAmount: 0,
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 1000000000000000000,
        outMaxAmount: 0
      })
    });
    exchangeInfoData56[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 1000000000000000000,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(37),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x00000000000000000000000000000000000000000000000000000000000dbce0, 37)
      })
    });

    allExchangeInfos[56] = ExchangeInfoDataWithEntityId({
      entityId: 0x00000000000000000000000000000000000000000000000000000000000dbce0,
      exchangeInfoData: exchangeInfoData56
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData57 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData57[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(122),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(122) -
          getCount(0x00000000000000000000000000000000000000000000000000000000000e4630, 122),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 1285714285714285714
      })
    });
    exchangeInfoData57[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(122),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x00000000000000000000000000000000000000000000000000000000000e4630, 122) - 1
      })
    });

    allExchangeInfos[57] = ExchangeInfoDataWithEntityId({
      entityId: 0x00000000000000000000000000000000000000000000000000000000000e4630,
      exchangeInfoData: exchangeInfoData57
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData58 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData58[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(89),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(89) -
          getCount(0x00000000000000000000000000000000000000000000000000000000000e5ca2, 89),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 12000000000000000000
      })
    });
    exchangeInfoData58[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(89),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x00000000000000000000000000000000000000000000000000000000000e5ca2, 89) - 1
      })
    });

    allExchangeInfos[58] = ExchangeInfoDataWithEntityId({
      entityId: 0x00000000000000000000000000000000000000000000000000000000000e5ca2,
      exchangeInfoData: exchangeInfoData58
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData59 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData59[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(100),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(100) -
          getCount(0x00000000000000000000000000000000000000000000000000000000000e8ecd, 100),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 10000000000000000000
      })
    });
    exchangeInfoData59[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(100),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x00000000000000000000000000000000000000000000000000000000000e8ecd, 100) - 1
      })
    });

    allExchangeInfos[59] = ExchangeInfoDataWithEntityId({
      entityId: 0x00000000000000000000000000000000000000000000000000000000000e8ecd,
      exchangeInfoData: exchangeInfoData59
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData60 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData60[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(97),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(97) -
          getCount(0x00000000000000000000000000000000000000000000000000000000000e9052, 97),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 4142857142857142857
      })
    });
    exchangeInfoData60[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(97),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x00000000000000000000000000000000000000000000000000000000000e9052, 97) - 1
      })
    });

    allExchangeInfos[60] = ExchangeInfoDataWithEntityId({
      entityId: 0x00000000000000000000000000000000000000000000000000000000000e9052,
      exchangeInfoData: exchangeInfoData60
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData61 = new ExchangeInfoDataWithExchangeId[](1);
    exchangeInfoData61[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(122),
        inUnitAmount: 1,
        inMaxAmount: 0,
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 1000000000000000000,
        outMaxAmount: 0
      })
    });

    allExchangeInfos[61] = ExchangeInfoDataWithEntityId({
      entityId: 0x0000000000000000000000000000000000000000000000000000000000123237,
      exchangeInfoData: exchangeInfoData61
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData62 = new ExchangeInfoDataWithExchangeId[](1);
    exchangeInfoData62[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.NativeCurrency,
        inResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        inUnitAmount: 35000000000000,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(17),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x00000000000000000000000000000000000000000000000000000000001a19ba, 17)
      })
    });

    allExchangeInfos[62] = ExchangeInfoDataWithEntityId({
      entityId: 0x00000000000000000000000000000000000000000000000000000000001a19ba,
      exchangeInfoData: exchangeInfoData62
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData63 = new ExchangeInfoDataWithExchangeId[](1);
    exchangeInfoData63[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.NativeCurrency,
        inResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        inUnitAmount: 5000000000000000,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(11),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x00000000000000000000000000000000000000000000000000000000002a3b09, 11)
      })
    });

    allExchangeInfos[63] = ExchangeInfoDataWithEntityId({
      entityId: 0x00000000000000000000000000000000000000000000000000000000002a3b09,
      exchangeInfoData: exchangeInfoData63
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData64 = new ExchangeInfoDataWithExchangeId[](1);
    exchangeInfoData64[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.NativeCurrency,
        inResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        inUnitAmount: 100000000000000,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(5),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x00000000000000000000000000000000000000000000000000000000002c3bb9, 5)
      })
    });

    allExchangeInfos[64] = ExchangeInfoDataWithEntityId({
      entityId: 0x00000000000000000000000000000000000000000000000000000000002c3bb9,
      exchangeInfoData: exchangeInfoData64
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData65 = new ExchangeInfoDataWithExchangeId[](1);
    exchangeInfoData65[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.NativeCurrency,
        inResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        inUnitAmount: 100000000000000,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(6),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x00000000000000000000000000000000000000000000000000000000002c3bc2, 6)
      })
    });

    allExchangeInfos[65] = ExchangeInfoDataWithEntityId({
      entityId: 0x00000000000000000000000000000000000000000000000000000000002c3bc2,
      exchangeInfoData: exchangeInfoData65
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData66 = new ExchangeInfoDataWithExchangeId[](1);
    exchangeInfoData66[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.NativeCurrency,
        inResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        inUnitAmount: 5000000000000000,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(12),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x00000000000000000000000000000000000000000000000000000000002c3cb9, 12)
      })
    });

    allExchangeInfos[66] = ExchangeInfoDataWithEntityId({
      entityId: 0x00000000000000000000000000000000000000000000000000000000002c3cb9,
      exchangeInfoData: exchangeInfoData66
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData67 = new ExchangeInfoDataWithExchangeId[](1);
    exchangeInfoData67[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.NativeCurrency,
        inResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        inUnitAmount: 10000000000000000,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(14),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x00000000000000000000000000000000000000000000000000000000002c4229, 14)
      })
    });

    allExchangeInfos[67] = ExchangeInfoDataWithEntityId({
      entityId: 0x00000000000000000000000000000000000000000000000000000000002c4229,
      exchangeInfoData: exchangeInfoData67
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData68 = new ExchangeInfoDataWithExchangeId[](1);
    exchangeInfoData68[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.NativeCurrency,
        inResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        inUnitAmount: 10000000000000000,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(13),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x00000000000000000000000000000000000000000000000000000000002cbda8, 13)
      })
    });

    allExchangeInfos[68] = ExchangeInfoDataWithEntityId({
      entityId: 0x00000000000000000000000000000000000000000000000000000000002cbda8,
      exchangeInfoData: exchangeInfoData68
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData69 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData69[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(89),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(89) -
          getCount(0x000000000000000000000000000000000000000000000000000000000036cb7d, 89),
        outResourceType: ResourceType.NativeCurrency,
        outResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        outUnitAmount: 0,
        outMaxAmount: 3846153846153846
      })
    });
    exchangeInfoData69[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.NativeCurrency,
        inResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(89),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x000000000000000000000000000000000000000000000000000000000036cb7d, 89) - 1
      })
    });

    allExchangeInfos[69] = ExchangeInfoDataWithEntityId({
      entityId: 0x000000000000000000000000000000000000000000000000000000000036cb7d,
      exchangeInfoData: exchangeInfoData69
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData70 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData70[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(65),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(65) -
          getCount(0x00000000000000000000000000000000000000000000000000000000006e8472, 65),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 5007225433526011560
      })
    });
    exchangeInfoData70[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(65),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x00000000000000000000000000000000000000000000000000000000006e8472, 65) - 1
      })
    });

    allExchangeInfos[70] = ExchangeInfoDataWithEntityId({
      entityId: 0x00000000000000000000000000000000000000000000000000000000006e8472,
      exchangeInfoData: exchangeInfoData70
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData71 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData71[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(75),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(75) -
          getCount(0x00000000000000000000000000000000000000000000000000000000006e8954, 75),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 9119579500657030223
      })
    });
    exchangeInfoData71[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(75),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x00000000000000000000000000000000000000000000000000000000006e8954, 75) - 1
      })
    });

    allExchangeInfos[71] = ExchangeInfoDataWithEntityId({
      entityId: 0x00000000000000000000000000000000000000000000000000000000006e8954,
      exchangeInfoData: exchangeInfoData71
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData72 = new ExchangeInfoDataWithExchangeId[](1);
    exchangeInfoData72[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.NativeCurrency,
        inResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        inUnitAmount: 80000000000000,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(20),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x00000000000000000000000000000000000000000000000000000000007f4ceb, 20)
      })
    });

    allExchangeInfos[72] = ExchangeInfoDataWithEntityId({
      entityId: 0x00000000000000000000000000000000000000000000000000000000007f4ceb,
      exchangeInfoData: exchangeInfoData72
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData73 = new ExchangeInfoDataWithExchangeId[](1);
    exchangeInfoData73[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.NativeCurrency,
        inResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        inUnitAmount: 500000000000000,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(170),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x00000000000000000000000000000000000000000000000000000000007f875b, 170)
      })
    });

    allExchangeInfos[73] = ExchangeInfoDataWithEntityId({
      entityId: 0x00000000000000000000000000000000000000000000000000000000007f875b,
      exchangeInfoData: exchangeInfoData73
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData74 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData74[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(55),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(55) -
          getCount(0x00000000000000000000000000000000000000000000000000000000007fd834, 55),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 5008375209380234505
      })
    });
    exchangeInfoData74[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(55),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x00000000000000000000000000000000000000000000000000000000007fd834, 55) - 1
      })
    });

    allExchangeInfos[74] = ExchangeInfoDataWithEntityId({
      entityId: 0x00000000000000000000000000000000000000000000000000000000007fd834,
      exchangeInfoData: exchangeInfoData74
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData75 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData75[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(70),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(70) -
          getCount(0x00000000000000000000000000000000000000000000000000000000007fe21c, 70),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        outUnitAmount: 0,
        outMaxAmount: 11666666666666666666
      })
    });
    exchangeInfoData75[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(70),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x00000000000000000000000000000000000000000000000000000000007fe21c, 70) - 1
      })
    });

    allExchangeInfos[75] = ExchangeInfoDataWithEntityId({
      entityId: 0x00000000000000000000000000000000000000000000000000000000007fe21c,
      exchangeInfoData: exchangeInfoData75
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData76 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData76[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(95),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(95) -
          getCount(0x00000000000000000000000000000000000000000000000000000000007fe2cc, 95),
        outResourceType: ResourceType.NativeCurrency,
        outResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        outUnitAmount: 0,
        outMaxAmount: 41022099447513812
      })
    });
    exchangeInfoData76[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.NativeCurrency,
        inResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(95),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x00000000000000000000000000000000000000000000000000000000007fe2cc, 95) - 1
      })
    });

    allExchangeInfos[76] = ExchangeInfoDataWithEntityId({
      entityId: 0x00000000000000000000000000000000000000000000000000000000007fe2cc,
      exchangeInfoData: exchangeInfoData76
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData77 = new ExchangeInfoDataWithExchangeId[](2);
    exchangeInfoData77[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(88),
        inUnitAmount: 1,
        inMaxAmount: numMaxInChest(88) -
          getCount(0x0000000000000000000000000000000000000000000000000000000000894fad, 88),
        outResourceType: ResourceType.ERC20,
        outResourceId: encodeAddressExchangeResourceId(0x9c0153C56b460656DF4533246302d42Bd2b49947),
        outUnitAmount: 0,
        outMaxAmount: 10000000000000000000000
      })
    });
    exchangeInfoData77[1] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.ERC20,
        inResourceId: encodeAddressExchangeResourceId(0x9c0153C56b460656DF4533246302d42Bd2b49947),
        inUnitAmount: 0,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(88),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x0000000000000000000000000000000000000000000000000000000000894fad, 88) - 1
      })
    });

    allExchangeInfos[77] = ExchangeInfoDataWithEntityId({
      entityId: 0x0000000000000000000000000000000000000000000000000000000000894fad,
      exchangeInfoData: exchangeInfoData77
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData78 = new ExchangeInfoDataWithExchangeId[](1);
    exchangeInfoData78[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: BUY_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.Object,
        inResourceId: encodeObjectExchangeResourceId(165),
        inUnitAmount: 1,
        inMaxAmount: 19,
        outResourceType: ResourceType.NativeCurrency,
        outResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        outUnitAmount: 10000000000000,
        outMaxAmount: 191900000000000
      })
    });

    allExchangeInfos[78] = ExchangeInfoDataWithEntityId({
      entityId: 0x00000000000000000000000000000000000000000000000000000000008c1c9d,
      exchangeInfoData: exchangeInfoData78
    });

    ExchangeInfoDataWithExchangeId[] memory exchangeInfoData79 = new ExchangeInfoDataWithExchangeId[](1);
    exchangeInfoData79[0] = ExchangeInfoDataWithExchangeId({
      exchangeId: SELL_EXCHANGE_ID,
      exchangeInfoData: ExchangeInfoData({
        inResourceType: ResourceType.NativeCurrency,
        inResourceId: encodeAddressExchangeResourceId(0x0000000000000000000000000000000000000000),
        inUnitAmount: 1000000000000000,
        inMaxAmount: type(uint256).max,
        outResourceType: ResourceType.Object,
        outResourceId: encodeObjectExchangeResourceId(122),
        outUnitAmount: 1,
        outMaxAmount: getCount(0x00000000000000000000000000000000000000000000000000000000008ee514, 122)
      })
    });

    allExchangeInfos[79] = ExchangeInfoDataWithEntityId({
      entityId: 0x00000000000000000000000000000000000000000000000000000000008ee514,
      exchangeInfoData: exchangeInfoData79
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
