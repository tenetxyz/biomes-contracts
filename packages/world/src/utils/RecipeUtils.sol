// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { Recipes, RecipesData } from "../codegen/tables/Recipes.sol";

import { NullObjectTypeId } from "../ObjectTypeIds.sol";

function createSingleInputWithStationRecipe(
  uint8 stationObjectTypeId,
  uint8 inputObjectTypeId,
  uint8 inputObjectTypeAmount,
  uint8 outputObjectTypeId,
  uint8 outputObjectTypeAmount
) {
  uint8[] memory inputObjectTypeIds = new uint8[](1);
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
  uint8 inputObjectTypeId,
  uint8 inputObjectTypeAmount,
  uint8 outputObjectTypeId,
  uint8 outputObjectTypeAmount
) {
  createSingleInputWithStationRecipe(
    NullObjectTypeId,
    inputObjectTypeId,
    inputObjectTypeAmount,
    outputObjectTypeId,
    outputObjectTypeAmount
  );
}

function createDoubleInputWithStationRecipe(
  uint8 stationObjectTypeId,
  uint8 inputObjectTypeId1,
  uint8 inputObjectTypeAmount1,
  uint8 inputObjectTypeId2,
  uint8 inputObjectTypeAmount2,
  uint8 outputObjectTypeId,
  uint8 outputObjectTypeAmount
) {
  uint8[] memory inputObjectTypeIds = new uint8[](2);
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
  uint8 inputObjectTypeId1,
  uint8 inputObjectTypeAmount1,
  uint8 inputObjectTypeId2,
  uint8 inputObjectTypeAmount2,
  uint8 outputObjectTypeId,
  uint8 outputObjectTypeAmount
) {
  createDoubleInputWithStationRecipe(
    NullObjectTypeId,
    inputObjectTypeId1,
    inputObjectTypeAmount1,
    inputObjectTypeId2,
    inputObjectTypeAmount2,
    outputObjectTypeId,
    outputObjectTypeAmount
  );
}
