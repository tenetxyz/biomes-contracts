// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Program } from "../codegen/tables/Program.sol";
import { DisplayContent, DisplayContentData } from "../codegen/tables/DisplayContent.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { DisplayContentType } from "../codegen/common.sol";

import { Position, ReversePosition } from "../utils/Vec3Storage.sol";

import { IDisplayProgram } from "../prototypes/IDisplayProgram.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { getLatestEnergyData } from "../utils/EnergyUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { EntityId } from "../EntityId.sol";
import { Vec3 } from "../Vec3.sol";

contract DisplaySystem is System {
  using ObjectTypeLib for ObjectTypeId;

  function getDisplayContent(EntityId entityId) public view returns (DisplayContentData memory) {
    require(entityId.exists(), "Entity does not exist");

    EntityId baseEntityId = entityId.baseEntityId();
    ObjectTypeId objectTypeId = ObjectType._get(baseEntityId);
    if (!objectTypeId.isSmartDisplay()) {
      return DisplayContent._get(baseEntityId);
    }
    Vec3 entityCoord = Position._get(baseEntityId);

    (EntityId forceFieldEntityId, ) = getForceField(entityCoord);
    uint256 machineEnergyLevel = 0;
    if (forceFieldEntityId.exists()) {
      (EnergyData memory machineData, , ) = getLatestEnergyData(forceFieldEntityId);
      machineEnergyLevel = machineData.energy;
    }
    if (machineEnergyLevel > 0) {
      // We can call the program directly as we are a root system
      return IDisplayProgram(baseEntityId.getProgramAddress()).getDisplayContent(baseEntityId);
    }

    return DisplayContentData({ contentType: DisplayContentType.None, content: bytes("") });
  }

  function setDisplayContent(EntityId entityId, DisplayContentData memory content) public {
    EntityId baseEntityId = entityId.baseEntityId();
    require(ObjectType._get(baseEntityId).canHoldDisplay(), "You can only set the display content of a basic display");
    Vec3 entityCoord = Position._get(baseEntityId);
    require(ReversePosition._get(entityCoord) == baseEntityId, "Entity is not at the specified position");

    DisplayContent._set(baseEntityId, content);
  }
}
