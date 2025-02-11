// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Recipes, RecipesData } from "../codegen/tables/Recipes.sol";

import { NullObjectTypeId } from "../ObjectTypeIds.sol";

function createSingleInputWithStationRecipe(
  uint16 stationObjectTypeId,
  uint16 inputObjectTypeId,
  uint16 inputObjectTypeAmount,
  uint16 outputObjectTypeId,
  uint16 outputObjectTypeAmount
) {
  uint16[] memory inputObjectTypeIds = new uint16[](1);
  inputObjectTypeIds[0] = inputObjectTypeId;
  uint16[] memory inputObjectTypeAmounts = new uint16[](1);
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
  uint16 inputObjectTypeId,
  uint16 inputObjectTypeAmount,
  uint16 outputObjectTypeId,
  uint16 outputObjectTypeAmount
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
  uint16 stationObjectTypeId,
  uint16 inputObjectTypeId1,
  uint16 inputObjectTypeAmount1,
  uint16 inputObjectTypeId2,
  uint16 inputObjectTypeAmount2,
  uint16 outputObjectTypeId,
  uint16 outputObjectTypeAmount
) {
  uint16[] memory inputObjectTypeIds = new uint16[](2);
  inputObjectTypeIds[0] = inputObjectTypeId1;
  inputObjectTypeIds[1] = inputObjectTypeId2;

  uint16[] memory inputObjectTypeAmounts = new uint16[](2);
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
  uint16 inputObjectTypeId1,
  uint16 inputObjectTypeAmount1,
  uint16 inputObjectTypeId2,
  uint16 inputObjectTypeAmount2,
  uint16 outputObjectTypeId,
  uint16 outputObjectTypeAmount
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
