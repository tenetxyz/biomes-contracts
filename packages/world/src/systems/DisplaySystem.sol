// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "../Types.sol";

import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Chip } from "../codegen/tables/Chip.sol";
import { DisplayContent, DisplayContentData } from "../codegen/tables/DisplayContent.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { DisplayContentType } from "../codegen/common.sol";

import { IDisplayChip } from "../prototypes/IDisplayChip.sol";
import { TextSignObjectID } from "../ObjectTypeIds.sol";
import { isSmartItem } from "../utils/ObjectTypeUtils.sol";
import { getLatestEnergyData } from "../utils/MachineUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { positionDataToVoxelCoord } from "../Utils.sol";
import { isBasicDisplay } from "../utils/ObjectTypeUtils.sol";
import { EntityId } from "../EntityId.sol";

contract DisplaySystem is System {
  function getDisplayContent(EntityId entityId) public view returns (DisplayContentData memory) {
    require(entityId.exists(), "Entity does not exist");

    EntityId baseEntityId = entityId.baseEntityId();
    uint16 objectTypeId = ObjectType._get(baseEntityId);
    if (!isSmartItem(objectTypeId)) {
      return DisplayContent._get(baseEntityId);
    }
    VoxelCoord memory entityCoord = positionDataToVoxelCoord(Position._get(baseEntityId));

    EntityId forceFieldEntityId = getForceField(entityCoord);
    uint256 machineEnergyLevel = 0;
    if (forceFieldEntityId.exists()) {
      EnergyData memory machineData = getLatestEnergyData(forceFieldEntityId);
      machineEnergyLevel = machineData.energy;
    }
    if (machineEnergyLevel > 0) {
      // We can call the chip directly as we are a root system
      return IDisplayChip(baseEntityId.getChipAddress()).getDisplayContent(baseEntityId);
    }

    return DisplayContentData({ contentType: DisplayContentType.None, content: bytes("") });
  }

  function setDisplayContent(EntityId entityId, DisplayContentData memory content) public {
    EntityId baseEntityId = entityId.baseEntityId();
    require(isBasicDisplay(ObjectType._get(baseEntityId)), "You can only set the display content of a basic display");
    VoxelCoord memory entityCoord = positionDataToVoxelCoord(Position._get(baseEntityId));
    require(
      ReversePosition._get(entityCoord.x, entityCoord.y, entityCoord.z) == baseEntityId,
      "Entity is not at the specified position"
    );

    DisplayContent._set(baseEntityId, content);
  }
}
