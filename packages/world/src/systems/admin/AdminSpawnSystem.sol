// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";
import { ROOT_NAMESPACE_ID } from "@latticexyz/world/src/constants.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { Position } from "../../codegen/tables/Position.sol";
import { ReversePosition } from "../../codegen/tables/ReversePosition.sol";
import { InventoryObjects } from "../../codegen/tables/InventoryObjects.sol";
import { ObjectTypeMetadata } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { Chip, ChipData } from "../../codegen/tables/Chip.sol";

import { inWorldBorder, getTerrainObjectTypeId, getUniqueEntity } from "../../Utils.sol";
import { PlayerObjectID, WaterObjectID, ForceFieldObjectID } from "../../ObjectTypeIds.sol";
import { updateChipBatteryLevel } from "../../utils/ChipUtils.sol";
import { canHoldInventory } from "../../utils/ObjectTypeUtils.sol";

contract AdminSpawnSystem is System {
  function setObjectAtCoord(uint8 objectTypeId, VoxelCoord memory coord) public {
    AccessControl.requireOwner(ROOT_NAMESPACE_ID, _msgSender());
    require(inWorldBorder(coord), "AdminTerrainSystem: cannot build outside world border");
    require(getTerrainObjectTypeId(coord) != WaterObjectID, "AdminTerrainSystem: cannot build on water block");
    require(ObjectTypeMetadata._getIsBlock(objectTypeId), "AdminTerrainSystem: object type is not a block");

    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    if (entityId == bytes32(0)) {
      entityId = getUniqueEntity();
      ReversePosition._set(coord.x, coord.y, coord.z, entityId);
    } else {
      uint8 currentObjectTypeId = ObjectType._get(entityId);
      require(
        InventoryObjects._lengthObjectTypeIds(entityId) == 0,
        "AdminTerrainSystem: Cannot build where there are dropped objects"
      );
      ChipData memory chipData = updateChipBatteryLevel(entityId);
      require(
        chipData.chipAddress == address(0) && chipData.batteryLevel == 0,
        "AdminTerrainSystem: chip is attached to entity"
      );
      require(
        currentObjectTypeId != PlayerObjectID &&
          currentObjectTypeId != ForceFieldObjectID &&
          !canHoldInventory(currentObjectTypeId),
        "AdminTerrainSystem: invaid overwrite"
      );
      if (currentObjectTypeId == objectTypeId) {
        // no-op
        return;
      }
    }
    ObjectType._set(entityId, objectTypeId);
    Position._set(entityId, coord.x, coord.y, coord.z);
  }

  function setObjectAtCoord(uint8 objectTypeId, VoxelCoord[] memory coord) public {
    AccessControl.requireOwner(ROOT_NAMESPACE_ID, _msgSender());
    for (uint i = 0; i < coord.length; i++) {
      setObjectAtCoord(objectTypeId, coord[i]);
    }
  }

  function setObjectAtCoord(uint8[] memory objectTypeId, VoxelCoord[] memory coord) public {
    AccessControl.requireOwner(ROOT_NAMESPACE_ID, _msgSender());
    require(objectTypeId.length == coord.length, "AdminTerrainSystem: objectTypeId and coord length mismatch");
    for (uint i = 0; i < coord.length; i++) {
      setObjectAtCoord(objectTypeId[i], coord[i]);
    }
  }
}
