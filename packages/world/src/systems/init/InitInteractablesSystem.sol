// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { WorkbenchObjectID } from "../../ObjectTypeIds.sol";

import { ObjectTypeId } from "../../ObjectTypeIds.sol";
import { ChestObjectID, SmartChestObjectID, ThermoblasterObjectID, PowerStoneObjectID, WorkbenchObjectID, DyeomaticObjectID, ForceFieldObjectID, TextSignObjectID, SmartTextSignObjectID, PipeObjectID, SpawnTileObjectID, BedObjectID } from "../../ObjectTypeIds.sol";
import { AnyLumberObjectID, AnyGlassObjectID, StoneObjectID, ClayObjectID, SandObjectID, AnyLogObjectID, CoalOreObjectID, GlassObjectID, MoonstoneObjectID, SilverBarObjectID, NeptuniumOreObjectID, AnyCottonBlockObjectID } from "../../ObjectTypeIds.sol";

import { createSingleInputRecipe, createDoubleInputRecipe, createSingleInputWithStationRecipe, createDoubleInputWithStationRecipe } from "../../utils/RecipeUtils.sol";

contract InitInteractablesSystem is System {
  function createInteractableBlock(
    ObjectTypeId objectTypeId,
    uint32 mass,
    uint16 maxInventorySlots,
    uint16 stackable
  ) internal {
    ObjectTypeMetadata._set(
      objectTypeId,
      ObjectTypeMetadataData({
        stackable: stackable,
        maxInventorySlots: maxInventorySlots,
        mass: mass,
        energy: 0,
        canPassThrough: false
      })
    );
  }

  function initInteractableObjectTypes() public {
    createInteractableBlock(ChestObjectID, 20, 24, 1);
    createInteractableBlock(SmartChestObjectID, 20, 24, 1);
    createInteractableBlock(TextSignObjectID, 20, 0, 99);
    createInteractableBlock(SmartTextSignObjectID, 20, 0, 99);
    createInteractableBlock(ThermoblasterObjectID, 80, 0, 1);
    createInteractableBlock(WorkbenchObjectID, 20, 0, 1);
    createInteractableBlock(DyeomaticObjectID, 80, 0, 1);
    createInteractableBlock(PowerStoneObjectID, 80, 0, 1);
    createInteractableBlock(ForceFieldObjectID, 80, 0, 99);
    createInteractableBlock(PipeObjectID, 80, 0, 99);
    createInteractableBlock(SpawnTileObjectID, 80, 0, 99);
    createInteractableBlock(BedObjectID, 80, 36, 1);
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
    createDoubleInputWithStationRecipe(
      ThermoblasterObjectID,
      ForceFieldObjectID,
      1,
      NeptuniumOreObjectID,
      4,
      SpawnTileObjectID,
      1
    );

    createDoubleInputWithStationRecipe(
      WorkbenchObjectID,
      AnyLumberObjectID,
      8,
      AnyCottonBlockObjectID,
      8,
      BedObjectID,
      1
    );
  }
}
