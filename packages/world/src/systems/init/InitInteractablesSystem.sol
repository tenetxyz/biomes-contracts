// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { ObjectTypeSchema, ObjectTypeSchemaData } from "../../codegen/tables/ObjectTypeSchema.sol";
import { WorkbenchObjectID } from "../../ObjectTypeIds.sol";

import { ChestObjectID, ThermoblasterObjectID, PowerStoneObjectID, WorkbenchObjectID, DyeomaticObjectID, ForceFieldObjectID, TextSignObjectID, WoodFrameSmallObjectID, WoodFrameMediumObjectID, WoodFrameLargeObjectID } from "../../ObjectTypeIds.sol";
import { AnyLumberObjectID, AnyGlassObjectID, StoneObjectID, ClayObjectID, SandObjectID, AnyLogObjectID, CoalOreObjectID, GlassObjectID, MoonstoneObjectID } from "../../ObjectTypeIds.sol";

import { createSingleInputRecipe, createDoubleInputRecipe, createSingleInputWithStationRecipe, createDoubleInputWithStationRecipe } from "../../utils/RecipeUtils.sol";

contract InitInteractablesSystem is System {
  function createInteractableBlock(
    uint8 objectTypeId,
    uint16 miningDifficulty,
    uint8 stackable,
    VoxelCoord[] memory relativePositions
  ) internal {
    ObjectTypeMetadata._set(
      objectTypeId,
      ObjectTypeMetadataData({
        isBlock: true,
        isTool: false,
        miningDifficulty: miningDifficulty,
        stackable: stackable,
        durability: 0,
        damage: 0
      })
    );

    if (relativePositions.length > 0) {
      int16[] memory relativePositionsX = new int16[](relativePositions.length);
      int16[] memory relativePositionsY = new int16[](relativePositions.length);
      int16[] memory relativePositionsZ = new int16[](relativePositions.length);
      for (uint i = 0; i < relativePositions.length; i++) {
        relativePositionsX[i] = relativePositions[i].x;
        relativePositionsY[i] = relativePositions[i].y;
        relativePositionsZ[i] = relativePositions[i].z;
      }
      ObjectTypeSchema._set(objectTypeId, relativePositionsX, relativePositionsY, relativePositionsZ);
    }
  }

  function initInteractableObjectTypes() public {
    createInteractableBlock(ChestObjectID, 8, 1, new VoxelCoord[](0));
    VoxelCoord[] memory textSignRelativePositions = new VoxelCoord[](1);
    textSignRelativePositions[0] = VoxelCoord(0, 1, 0);
    createInteractableBlock(TextSignObjectID, 5, 99, textSignRelativePositions);

    createInteractableBlock(WoodFrameSmallObjectID, 5, 99, new VoxelCoord[](0));

    VoxelCoord[] memory woodenFrameMediumRelativePositions = new VoxelCoord[](3);
    woodenFrameMediumRelativePositions[0] = VoxelCoord(0, 1, 0);
    woodenFrameMediumRelativePositions[1] = VoxelCoord(1, 0, 0);
    woodenFrameMediumRelativePositions[2] = VoxelCoord(1, 1, 0);
    createInteractableBlock(WoodFrameMediumObjectID, 10, 99, woodenFrameMediumRelativePositions);

    VoxelCoord[] memory woodenFrameLargeRelativePositions = new VoxelCoord[](15);
    woodenFrameLargeRelativePositions[0] = VoxelCoord(0, 1, 0);
    woodenFrameLargeRelativePositions[1] = VoxelCoord(0, 2, 0);
    woodenFrameLargeRelativePositions[2] = VoxelCoord(0, 3, 0);
    woodenFrameLargeRelativePositions[3] = VoxelCoord(1, 0, 0);
    woodenFrameLargeRelativePositions[4] = VoxelCoord(1, 1, 0);
    woodenFrameLargeRelativePositions[5] = VoxelCoord(1, 2, 0);
    woodenFrameLargeRelativePositions[6] = VoxelCoord(1, 3, 0);
    woodenFrameLargeRelativePositions[7] = VoxelCoord(2, 0, 0);
    woodenFrameLargeRelativePositions[8] = VoxelCoord(2, 1, 0);
    woodenFrameLargeRelativePositions[9] = VoxelCoord(2, 2, 0);
    woodenFrameLargeRelativePositions[10] = VoxelCoord(2, 3, 0);
    woodenFrameLargeRelativePositions[11] = VoxelCoord(3, 0, 0);
    woodenFrameLargeRelativePositions[12] = VoxelCoord(3, 1, 0);
    woodenFrameLargeRelativePositions[13] = VoxelCoord(3, 2, 0);
    woodenFrameLargeRelativePositions[14] = VoxelCoord(3, 3, 0);
    createInteractableBlock(WoodFrameLargeObjectID, 15, 99, woodenFrameLargeRelativePositions);

    createInteractableBlock(ThermoblasterObjectID, 63, 1, new VoxelCoord[](0));
    createInteractableBlock(WorkbenchObjectID, 20, 1, new VoxelCoord[](0));
    createInteractableBlock(DyeomaticObjectID, 72, 1, new VoxelCoord[](0));
    createInteractableBlock(PowerStoneObjectID, 123, 1, new VoxelCoord[](0));
    createInteractableBlock(ForceFieldObjectID, 255, 99, new VoxelCoord[](0));
  }

  function initInteractablesRecipes() public {
    createSingleInputWithStationRecipe(WorkbenchObjectID, AnyLumberObjectID, 8, ChestObjectID, 1);
    createSingleInputWithStationRecipe(WorkbenchObjectID, AnyLumberObjectID, 4, TextSignObjectID, 1);
    createSingleInputWithStationRecipe(WorkbenchObjectID, AnyLumberObjectID, 8, WoodFrameSmallObjectID, 1);
    createSingleInputWithStationRecipe(WorkbenchObjectID, AnyLumberObjectID, 32, WoodFrameMediumObjectID, 1);
    createSingleInputWithStationRecipe(WorkbenchObjectID, AnyLumberObjectID, 72, WoodFrameLargeObjectID, 1);
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
  }
}
