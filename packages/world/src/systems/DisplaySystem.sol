// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { DisplayURI } from "../codegen/tables/DisplayURI.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";

import { Position, ReversePosition } from "../utils/Vec3Storage.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { getLatestEnergyData } from "../utils/EnergyUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { EntityId } from "../EntityId.sol";
import { Vec3 } from "../Vec3.sol";

contract DisplaySystem is System {
  using ObjectTypeLib for ObjectTypeId;

  function getDisplayURI(EntityId caller, EntityId entityId) public view returns (string memory) {
    require(entityId.exists(), "Entity does not exist");

    EntityId baseEntityId = entityId.baseEntityId();
    ObjectTypeId objectTypeId = ObjectType._get(baseEntityId);
    if (!objectTypeId.isSmartDisplay()) {
      // TODO: support display data for all entities?
      return "";
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
      // return baseEntityId.getProgram().getDisplayURI(caller, baseEntityId);
      return "";
    }

    return "";
  }

  function setDisplayURI(EntityId /* caller */, EntityId entityId, string memory uri) public {
    // TODO: auth?

    EntityId baseEntityId = entityId.baseEntityId();
    require(ObjectType._get(baseEntityId).canHoldDisplay(), "You can only set the display content of a basic display");
    Vec3 entityCoord = Position._get(baseEntityId);
    require(ReversePosition._get(entityCoord) == baseEntityId, "Entity is not at the specified position");

    DisplayURI._set(baseEntityId, uri);
  }
}
