// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Recipes, RecipesData } from "../codegen/tables/Recipes.sol";

import { VoxelCoord } from "@everlonxyz/utils/src/Types.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID } from "../ObjectTypeIds.sol";
import { OakLogObjectID, SakuraLogObjectID, BirchLogObjectID, RubberLogObjectID, OakLumberObjectID, SakuraLumberObjectID, RubberLumberObjectID, BirchLumberObjectID } from "../ObjectTypeIds.sol";
import { BlueOakLumberObjectID, BrownOakLumberObjectID, GreenOakLumberObjectID, MagentaOakLumberObjectID, OrangeOakLumberObjectID, PinkOakLumberObjectID, PurpleOakLumberObjectID, RedOakLumberObjectID, TanOakLumberObjectID, WhiteOakLumberObjectID, YellowOakLumberObjectID, BlackOakLumberObjectID, SilverOakLumberObjectID } from "../ObjectTypeIds.sol";

function createSingleInputWithStationRecipe(
  bytes32 stationObjectTypeId,
  bytes32 inputObjectTypeId,
  uint8 inputObjectTypeAmount,
  bytes32 outputObjectTypeId,
  uint8 outputObjectTypeAmount
) {
  bytes32[] memory inputObjectTypeIds = new bytes32[](1);
  inputObjectTypeIds[0] = inputObjectTypeId;
  uint8[] memory inputObjectTypeAmounts = new uint8[](1);
  inputObjectTypeAmounts[0] = inputObjectTypeAmount;

  // Form recipe id from input and output object type ids
  bytes32 recipeId = keccak256(
    abi.encodePacked(inputObjectTypeId, inputObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount)
  );
  Recipes.set(
    recipeId,
    RecipesData({
      stationObjectTypeId: stationObjectTypeId,
      inputObjectTypeIds: inputObjectTypeIds,
      inputObjectTypeAmounts: inputObjectTypeAmounts,
      outputObjectTypeId: outputObjectTypeId,
      outputObjectTypeAmount: outputObjectTypeAmount
    })
  );
}

function createSingleInputRecipe(
  bytes32 inputObjectTypeId,
  uint8 inputObjectTypeAmount,
  bytes32 outputObjectTypeId,
  uint8 outputObjectTypeAmount
) {
  createSingleInputWithStationRecipe(
    bytes32(0),
    inputObjectTypeId,
    inputObjectTypeAmount,
    outputObjectTypeId,
    outputObjectTypeAmount
  );
}

function createDoubleInputWithStationRecipe(
  bytes32 stationObjectTypeId,
  bytes32 inputObjectTypeId1,
  uint8 inputObjectTypeAmount1,
  bytes32 inputObjectTypeId2,
  uint8 inputObjectTypeAmount2,
  bytes32 outputObjectTypeId,
  uint8 outputObjectTypeAmount
) {
  bytes32[] memory inputObjectTypeIds = new bytes32[](2);
  inputObjectTypeIds[0] = inputObjectTypeId1;
  inputObjectTypeIds[1] = inputObjectTypeId2;

  uint8[] memory inputObjectTypeAmounts = new uint8[](2);
  inputObjectTypeAmounts[0] = inputObjectTypeAmount1;
  inputObjectTypeAmounts[1] = inputObjectTypeAmount2;

  // Form recipe id from input and output object type ids
  bytes32 recipeId = keccak256(
    abi.encodePacked(
      inputObjectTypeId1,
      inputObjectTypeAmount1,
      inputObjectTypeId2,
      inputObjectTypeAmount2,
      outputObjectTypeId,
      outputObjectTypeAmount
    )
  );
  Recipes.set(
    recipeId,
    RecipesData({
      stationObjectTypeId: stationObjectTypeId,
      inputObjectTypeIds: inputObjectTypeIds,
      inputObjectTypeAmounts: inputObjectTypeAmounts,
      outputObjectTypeId: outputObjectTypeId,
      outputObjectTypeAmount: outputObjectTypeAmount
    })
  );
}

function createDoubleInputRecipe(
  bytes32 inputObjectTypeId1,
  uint8 inputObjectTypeAmount1,
  bytes32 inputObjectTypeId2,
  uint8 inputObjectTypeAmount2,
  bytes32 outputObjectTypeId,
  uint8 outputObjectTypeAmount
) {
  createDoubleInputWithStationRecipe(
    bytes32(0),
    inputObjectTypeId1,
    inputObjectTypeAmount1,
    inputObjectTypeId2,
    inputObjectTypeAmount2,
    outputObjectTypeId,
    outputObjectTypeAmount
  );
}

function createRecipeForAllLogVariations(
  uint8 logObjectTypeAmount,
  bytes32 outputObjectTypeId,
  uint8 outputObjectTypeAmount
) {
  createSingleInputRecipe(OakLogObjectID, logObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputRecipe(SakuraLogObjectID, logObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputRecipe(RubberLogObjectID, logObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputRecipe(BirchLogObjectID, logObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
}

function createRecipeForAllLogVariationsWithInput(
  uint8 logObjectTypeAmount,
  bytes32 inputObjectTypeId,
  uint8 inputObjectTypeAmount,
  bytes32 outputObjectTypeId,
  uint8 outputObjectTypeAmount
) {
  createDoubleInputRecipe(
    inputObjectTypeId,
    inputObjectTypeAmount,
    OakLogObjectID,
    logObjectTypeAmount,
    outputObjectTypeId,
    outputObjectTypeAmount
  );
  createDoubleInputRecipe(
    inputObjectTypeId,
    inputObjectTypeAmount,
    SakuraLogObjectID,
    logObjectTypeAmount,
    outputObjectTypeId,
    outputObjectTypeAmount
  );
  createDoubleInputRecipe(
    inputObjectTypeId,
    inputObjectTypeAmount,
    RubberLogObjectID,
    logObjectTypeAmount,
    outputObjectTypeId,
    outputObjectTypeAmount
  );
  createDoubleInputRecipe(
    inputObjectTypeId,
    inputObjectTypeAmount,
    BirchLogObjectID,
    logObjectTypeAmount,
    outputObjectTypeId,
    outputObjectTypeAmount
  );
}

function createRecipeForAllLogVariationsWithInputStation(
  bytes32 stationObjectTypeId,
  uint8 logObjectTypeAmount,
  bytes32 inputObjectTypeId,
  uint8 inputObjectTypeAmount,
  bytes32 outputObjectTypeId,
  uint8 outputObjectTypeAmount
) {
  createDoubleInputWithStationRecipe(
    stationObjectTypeId,
    inputObjectTypeId,
    inputObjectTypeAmount,
    OakLogObjectID,
    logObjectTypeAmount,
    outputObjectTypeId,
    outputObjectTypeAmount
  );
  createDoubleInputWithStationRecipe(
    stationObjectTypeId,
    inputObjectTypeId,
    inputObjectTypeAmount,
    SakuraLogObjectID,
    logObjectTypeAmount,
    outputObjectTypeId,
    outputObjectTypeAmount
  );
  createDoubleInputWithStationRecipe(
    stationObjectTypeId,
    inputObjectTypeId,
    inputObjectTypeAmount,
    RubberLogObjectID,
    logObjectTypeAmount,
    outputObjectTypeId,
    outputObjectTypeAmount
  );
  createDoubleInputWithStationRecipe(
    stationObjectTypeId,
    inputObjectTypeId,
    inputObjectTypeAmount,
    BirchLogObjectID,
    logObjectTypeAmount,
    outputObjectTypeId,
    outputObjectTypeAmount
  );
}

function createRecipeForAllLumberVariations(
  uint8 lumberObjectTypeAmount,
  bytes32 outputObjectTypeId,
  uint8 outputObjectTypeAmount
) {
  createSingleInputRecipe(OakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputRecipe(SakuraLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputRecipe(RubberLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputRecipe(BirchLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputRecipe(BlueOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputRecipe(BrownOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputRecipe(GreenOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputRecipe(MagentaOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputRecipe(OrangeOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputRecipe(PinkOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputRecipe(PurpleOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputRecipe(RedOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputRecipe(TanOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputRecipe(WhiteOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputRecipe(YellowOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputRecipe(BlackOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputRecipe(SilverOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
}


function createRecipeForAllLumberVariationsWithInputStation(
  bytes32 stationObjectTypeId,
  uint8 lumberObjectTypeAmount,
  bytes32 outputObjectTypeId,
  uint8 outputObjectTypeAmount
) {
  createSingleInputWithStationRecipe(stationObjectTypeId, OakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputWithStationRecipe(stationObjectTypeId, SakuraLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputWithStationRecipe(stationObjectTypeId, RubberLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputWithStationRecipe(stationObjectTypeId, BirchLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputWithStationRecipe(stationObjectTypeId, BlueOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputWithStationRecipe(stationObjectTypeId, BrownOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputWithStationRecipe(stationObjectTypeId, GreenOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputWithStationRecipe(stationObjectTypeId, MagentaOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputWithStationRecipe(stationObjectTypeId, OrangeOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputWithStationRecipe(stationObjectTypeId, PinkOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputWithStationRecipe(stationObjectTypeId, PurpleOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputWithStationRecipe(stationObjectTypeId, RedOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputWithStationRecipe(stationObjectTypeId, TanOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputWithStationRecipe(stationObjectTypeId, WhiteOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputWithStationRecipe(stationObjectTypeId, YellowOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputWithStationRecipe(stationObjectTypeId, BlackOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  createSingleInputWithStationRecipe(stationObjectTypeId, SilverOakLumberObjectID, lumberObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
}
