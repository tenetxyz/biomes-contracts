// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Recipes, RecipesData } from "../codegen/tables/Recipes.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
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
  Recipes._set(
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
  bytes32 recipeId = inputObjectTypeId1 < inputObjectTypeId2
    ? keccak256(
      abi.encodePacked(
        inputObjectTypeId1,
        inputObjectTypeAmount1,
        inputObjectTypeId2,
        inputObjectTypeAmount2,
        outputObjectTypeId,
        outputObjectTypeAmount
      )
    )
    : keccak256(
      abi.encodePacked(
        inputObjectTypeId2,
        inputObjectTypeAmount2,
        inputObjectTypeId1,
        inputObjectTypeAmount1,
        outputObjectTypeId,
        outputObjectTypeAmount
      )
    );
  Recipes._set(
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
