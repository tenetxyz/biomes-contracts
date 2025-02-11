// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { IWorldCall } from "@latticexyz/world/src/IWorldKernel.sol";
import { revertWithBytes } from "@latticexyz/world/src/revertWithBytes.sol";
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
    ResourceId chipSystemId = Chip._getChipSystemId(baseEntityId);
    uint256 machineEnergyLevel = 0;
    if (forceFieldEntityId.exists()) {
      EnergyData memory machineData = getLatestEnergyData(forceFieldEntityId);
      machineEnergyLevel = machineData.energy;
    }
    if (chipSystemId.unwrap() != 0 && machineEnergyLevel > 0) {
      bytes memory getDisplayContentCall = abi.encodeCall(IDisplayChip.getDisplayContent, (baseEntityId));
      // TODO: maybe we should include staticcall in mud world
      bytes memory worldCall = abi.encodeCall(IWorldCall.call, (chipSystemId, getDisplayContentCall));
      (bool success, bytes memory returnData) = _world().staticcall(worldCall);

      if (!success) revertWithBytes(returnData);

      return abi.decode(returnData, (DisplayContentData));
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
