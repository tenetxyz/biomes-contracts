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

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord } from "../Utils.sol";
import { transferInventoryTool, transferInventoryNonTool } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina } from "../utils/PlayerUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

contract TransferSystem is System {
  function transferCommon(bytes32 playerEntityId, bytes32 srcEntityId, bytes32 dstEntityId) internal returns (uint8) {
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

    PlayerActivity._set(playerEntityId, block.timestamp);

    return dstObjectTypeId;
  }

  function transfer(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    uint8 transferObjectTypeId,
    uint16 numToTransfer,
    bytes memory extraData
  ) public payable {
    bytes32 playerEntityId = Player._get(_msgSender());
    uint8 dstObjectTypeId = transferCommon(playerEntityId, srcEntityId, dstEntityId);
    transferInventoryNonTool(srcEntityId, dstEntityId, dstObjectTypeId, transferObjectTypeId, numToTransfer);
  }

  function transferTool(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    bytes32 toolEntityId,
    bytes memory extraData
  ) public payable {
    bytes32 playerEntityId = Player._get(_msgSender());
    uint8 dstObjectTypeId = transferCommon(playerEntityId, srcEntityId, dstEntityId);
    uint8 toolObjectTypeId = transferInventoryTool(srcEntityId, dstEntityId, dstObjectTypeId, toolEntityId);
  }
}
