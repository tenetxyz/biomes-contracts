// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Player } from "../codegen/tables/Player.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { ItemMetadata } from "../codegen/tables/ItemMetadata.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { ExperiencePoints } from "../codegen/tables/ExperiencePoints.sol";
import { BlockMetadata } from "../codegen/tables/BlockMetadata.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord } from "../Utils.sol";
import { transferInventoryTool, transferInventoryNonTool } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina } from "../utils/PlayerUtils.sol";
import { mintXP } from "../utils/XPUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

contract TransferSystem is System {
  function transferCommon(bytes32 srcEntityId, bytes32 dstEntityId) internal returns (uint8) {
    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "TransferSystem: player does not exist");
    require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "TransferSystem: player isn't logged in");

    require(dstEntityId != srcEntityId, "TransferSystem: cannot transfer to self");
    VoxelCoord memory srcCoord = positionDataToVoxelCoord(Position._get(srcEntityId));
    VoxelCoord memory dstCoord = positionDataToVoxelCoord(Position._get(dstEntityId));
    require(inSurroundingCube(srcCoord, 1, dstCoord), "TransferSystem: destination out of range");

    regenHealth(playerEntityId);
    regenStamina(playerEntityId, playerEntityId == srcEntityId ? srcCoord : dstCoord);

    uint8 srcObjectTypeId = ObjectType._get(srcEntityId);
    uint8 dstObjectTypeId = ObjectType._get(dstEntityId);
    if (srcObjectTypeId == PlayerObjectID) {
      require(playerEntityId == srcEntityId, "TransferSystem: player does not own source inventory");
      require(dstObjectTypeId == ChestObjectID, "TransferSystem: cannot transfer to non-chest");
    } else if (dstObjectTypeId == PlayerObjectID) {
      require(playerEntityId == dstEntityId, "TransferSystem: player does not own destination inventory");
      require(srcObjectTypeId == ChestObjectID, "TransferSystem: cannot transfer from non-chest");
    } else {
      revert("TransferSystem: invalid transfer operation");
    }

    address owner = BlockMetadata._getOwner(playerEntityId == srcEntityId ? dstEntityId : srcEntityId);
    require(owner == address(0) || owner == _msgSender(), "TransferSystem: cannot transfer to/from a locked block");

    PlayerActivity._set(playerEntityId, block.timestamp);
    mintXP(playerEntityId, 1);

    return dstObjectTypeId;
  }

  function transfer(bytes32 srcEntityId, bytes32 dstEntityId, uint8 transferObjectTypeId, uint16 numToTransfer) public {
    uint8 dstObjectTypeId = transferCommon(srcEntityId, dstEntityId);
    transferInventoryNonTool(srcEntityId, dstEntityId, dstObjectTypeId, transferObjectTypeId, numToTransfer);
  }

  function transferTool(bytes32 srcEntityId, bytes32 dstEntityId, bytes32 toolEntityId) public {
    uint8 dstObjectTypeId = transferCommon(srcEntityId, dstEntityId);
    transferInventoryTool(srcEntityId, dstEntityId, dstObjectTypeId, toolEntityId);
  }
}
