// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";
import { ROOT_NAMESPACE_ID } from "@latticexyz/world/src/constants.sol";
import { VoxelCoord } from "../../Types.sol";

import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { Position } from "../../codegen/tables/Position.sol";
import { ReversePosition } from "../../codegen/tables/ReversePosition.sol";
import { InventoryObjects } from "../../codegen/tables/InventoryObjects.sol";
import { ObjectTypeMetadata } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { Chip } from "../../codegen/tables/Chip.sol";
import { Energy, EnergyData } from "../../codegen/tables/Energy.sol";
import { ObjectCategory } from "../../codegen/common.sol";

import { inWorldBorder, getUniqueEntity } from "../../Utils.sol";
import { PlayerObjectID, ForceFieldObjectID } from "../../ObjectTypeIds.sol";
import { isStorageContainer } from "../../utils/ObjectTypeUtils.sol";
import { updateMachineEnergyLevel } from "../../utils/MachineUtils.sol";
import { EntityId } from "../../EntityId.sol";

contract AdminSpawnSystem is System {
  function setObjectAtCoord(uint16 objectTypeId, VoxelCoord memory coord) public {
    AccessControl.requireOwner(ROOT_NAMESPACE_ID, _msgSender());
    require(inWorldBorder(coord), "Cannot build outside world border");
    require(ObjectTypeMetadata._getObjectCategory(objectTypeId) == ObjectCategory.Block, "Object type is not a block");

    EntityId entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    if (!entityId.exists()) {
      entityId = getUniqueEntity();
      ReversePosition._set(coord.x, coord.y, coord.z, entityId);
    } else {
      uint16 currentObjectTypeId = ObjectType._get(entityId);
      require(InventoryObjects._lengthObjectTypeIds(entityId) == 0, "Cannot build where there are dropped objects");
      require(Chip._getChipAddress(entityId) == address(0), "Chip is attached to entity");
      EnergyData memory energyData = updateMachineEnergyLevel(entityId);
      require(energyData.energy == 0, "Energy is attached to entity");
      require(
        currentObjectTypeId != PlayerObjectID &&
          currentObjectTypeId != ForceFieldObjectID &&
          !isStorageContainer(currentObjectTypeId),
        "Invalid overwrite"
      );
      if (currentObjectTypeId == objectTypeId) {
        // no-op
        return;
      }
    }
    ObjectType._set(entityId, objectTypeId);
    Position._set(entityId, coord.x, coord.y, coord.z);
  }

  function setObjectAtCoord(uint16 objectTypeId, VoxelCoord[] memory coord) public {
    AccessControl.requireOwner(ROOT_NAMESPACE_ID, _msgSender());
    for (uint i = 0; i < coord.length; i++) {
      setObjectAtCoord(objectTypeId, coord[i]);
    }
  }

  function setObjectAtCoord(uint16[] memory objectTypeId, VoxelCoord[] memory coord) public {
    AccessControl.requireOwner(ROOT_NAMESPACE_ID, _msgSender());
    require(objectTypeId.length == coord.length, "ObjectTypeId and coord length mismatch");
    for (uint i = 0; i < coord.length; i++) {
      setObjectAtCoord(objectTypeId[i], coord[i]);
    }
  }
}
