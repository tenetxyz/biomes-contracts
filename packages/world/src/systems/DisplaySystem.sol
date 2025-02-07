// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Chip, ChipData } from "../codegen/tables/Chip.sol";
import { DisplayContent, DisplayContentData } from "../codegen/tables/DisplayContent.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { DisplayContentType } from "../codegen/common.sol";

import { IDisplayChip } from "../prototypes/IDisplayChip.sol";
import { TextSignObjectID } from "../ObjectTypeIds.sol";
import { isSmartItem } from "../utils/ObjectTypeUtils.sol";
import { updateChipBatteryLevel } from "../utils/ChipUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { positionDataToVoxelCoord } from "../Utils.sol";
import { isBasicDisplay } from "../utils/ObjectTypeUtils.sol";
contract DisplaySystem is System {
  function getDisplayContent(bytes32 entityId) public view returns (DisplayContentData memory) {
    require(entityId != bytes32(0), "DisplaySystem: entity does not exist");

    bytes32 baseEntityId = BaseEntity._get(entityId);
    baseEntityId = baseEntityId == bytes32(0) ? entityId : baseEntityId;
    uint16 objectTypeId = ObjectType.get(baseEntityId);
    if (!isSmartItem(objectTypeId)) {
      return DisplayContent.get(baseEntityId);
    }
    VoxelCoord memory entityCoord = positionDataToVoxelCoord(Position.get(baseEntityId));

    bytes32 forceFieldEntityId = getForceField(entityCoord);
    ChipData memory chipData = Chip.get(baseEntityId);
    uint256 batteryLevel = chipData.batteryLevel;
    if (forceFieldEntityId != bytes32(0)) {
      ChipData memory forceFieldChipData = Chip.get(forceFieldEntityId);
      batteryLevel += forceFieldChipData.batteryLevel;
    }
    if (chipData.chipAddress != address(0) && batteryLevel > 0) {
      return IDisplayChip(chipData.chipAddress).getDisplayContent(baseEntityId);
    }

    return DisplayContentData({ contentType: DisplayContentType.None, content: bytes("") });
  }

  function setDisplayContent(bytes32 entityId, DisplayContentData memory content) public {
    bytes32 baseEntityId = BaseEntity._get(entityId);
    baseEntityId = baseEntityId == bytes32(0) ? entityId : baseEntityId;
    require(
      isBasicDisplay(ObjectType.get(baseEntityId)),
      "DisplaySystem: you can only set the display content of a basic display"
    );
    VoxelCoord memory entityCoord = positionDataToVoxelCoord(Position.get(baseEntityId));
    require(
      ReversePosition.get(entityCoord.x, entityCoord.y, entityCoord.z) == baseEntityId,
      "DisplaySystem: entity is not at the specified position"
    );

    DisplayContent.set(baseEntityId, content);
  }
}
