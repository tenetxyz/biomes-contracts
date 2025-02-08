// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { ObjectCategory } from "../../codegen/common.sol";
import { ObjectTypeSchema, ObjectTypeSchemaData } from "../../codegen/tables/ObjectTypeSchema.sol";
import { WorkbenchObjectID } from "../../ObjectTypeIds.sol";

import { ChestObjectID, SmartChestObjectID, ThermoblasterObjectID, PowerStoneObjectID, WorkbenchObjectID, DyeomaticObjectID, ForceFieldObjectID, TextSignObjectID, SmartTextSignObjectID, PipeObjectID } from "../../ObjectTypeIds.sol";
import { AnyLumberObjectID, AnyGlassObjectID, StoneObjectID, ClayObjectID, SandObjectID, AnyLogObjectID, CoalOreObjectID, GlassObjectID, MoonstoneObjectID, SilverBarObjectID } from "../../ObjectTypeIds.sol";

import { createSingleInputRecipe, createDoubleInputRecipe, createSingleInputWithStationRecipe, createDoubleInputWithStationRecipe } from "../../utils/RecipeUtils.sol";

contract InitInteractablesSystem is System {
  function createInteractableBlock(
    uint16 objectTypeId,
    uint32 mass,
    uint16 maxInventorySlots,
    uint16 stackable,
    VoxelCoord[] memory relativePositions
  ) internal {
    ObjectTypeMetadata._set(
      objectTypeId,
      ObjectTypeMetadataData({
        objectCategory: ObjectCategory.Block,
        stackable: stackable,
        maxInventorySlots: maxInventorySlots,
        mass: mass,
        energy: 0
      })
    );

    if (relativePositions.length > 0) {
      int32[] memory relativePositionsX = new int32[](relativePositions.length);
      int32[] memory relativePositionsY = new int32[](relativePositions.length);
      int32[] memory relativePositionsZ = new int32[](relativePositions.length);
      for (uint i = 0; i < relativePositions.length; i++) {
        relativePositionsX[i] = relativePositions[i].x;
        relativePositionsY[i] = relativePositions[i].y;
        relativePositionsZ[i] = relativePositions[i].z;
      }
      ObjectTypeSchema._set(objectTypeId, relativePositionsX, relativePositionsY, relativePositionsZ);
    }
  }

  function initInteractableObjectTypes() public {
    createInteractableBlock(ChestObjectID, 20, 24, 1, new VoxelCoord[](0));
    createInteractableBlock(SmartChestObjectID, 20, 24, 1, new VoxelCoord[](0));
    VoxelCoord[] memory textSignRelativePositions = new VoxelCoord[](1);
    textSignRelativePositions[0] = VoxelCoord(0, 1, 0);
    createInteractableBlock(TextSignObjectID, 20, 0, 99, textSignRelativePositions);
    createInteractableBlock(SmartTextSignObjectID, 20, 0, 99, textSignRelativePositions);
    createInteractableBlock(ThermoblasterObjectID, 80, 0, 1, new VoxelCoord[](0));
    createInteractableBlock(WorkbenchObjectID, 20, 0, 1, new VoxelCoord[](0));
    createInteractableBlock(DyeomaticObjectID, 80, 0, 1, new VoxelCoord[](0));
    createInteractableBlock(PowerStoneObjectID, 80, 0, 1, new VoxelCoord[](0));
    createInteractableBlock(ForceFieldObjectID, 80, 0, 99, new VoxelCoord[](0));
    createInteractableBlock(PipeObjectID, 80, 0, 99, new VoxelCoord[](0));
  }

  function initInteractablesRecipes() public {
    createSingleInputWithStationRecipe(WorkbenchObjectID, AnyLumberObjectID, 8, ChestObjectID, 1);
    createDoubleInputWithStationRecipe(
      WorkbenchObjectID,
      ChestObjectID,
      1,
      SilverBarObjectID,
      1,
      SmartChestObjectID,
      1
    );
    createSingleInputWithStationRecipe(WorkbenchObjectID, AnyLumberObjectID, 4, TextSignObjectID, 1);
    createDoubleInputWithStationRecipe(
      WorkbenchObjectID,
      TextSignObjectID,
      1,
      SilverBarObjectID,
      1,
      SmartTextSignObjectID,
      1
    );
    createSingleInputRecipe(AnyLogObjectID, 5, WorkbenchObjectID, 1);
    createSingleInputRecipe(StoneObjectID, 9, ThermoblasterObjectID, 1);
    createDoubleInputRecipe(ClayObjectID, 4, SandObjectID, 4, DyeomaticObjectID, 1);
    createDoubleInputRecipe(StoneObjectID, 6, MoonstoneObjectID, 2, PowerStoneObjectID, 1);
    createDoubleInputWithStationRecipe(
      ThermoblasterObjectID,
      StoneObjectID,
      30,
      AnyGlassObjectID,
      5,
      ForceFieldObjectID,
      1
    );
    createDoubleInputWithStationRecipe(WorkbenchObjectID, StoneObjectID, 4, SilverBarObjectID, 1, PipeObjectID, 1);
  }
}
