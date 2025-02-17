// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Recipes, RecipesData } from "../codegen/tables/Recipes.sol";

import { ObjectTypeId, NullObjectTypeId } from "../ObjectTypeIds.sol";

function createSingleInputWithStationRecipe(
  ObjectTypeId stationObjectTypeId,
  ObjectTypeId inputObjectTypeId,
  uint16 inputObjectTypeAmount,
  ObjectTypeId outputObjectTypeId,
  uint16 outputObjectTypeAmount
) {
  uint16[] memory inputObjectTypeIds = new uint16[](1);
  inputObjectTypeIds[0] = inputObjectTypeId.unwrap();
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
  ObjectTypeId inputObjectTypeId,
  uint16 inputObjectTypeAmount,
  ObjectTypeId outputObjectTypeId,
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
  ObjectTypeId stationObjectTypeId,
  ObjectTypeId inputObjectTypeId1,
  uint16 inputObjectTypeAmount1,
  ObjectTypeId inputObjectTypeId2,
  uint16 inputObjectTypeAmount2,
  ObjectTypeId outputObjectTypeId,
  uint16 outputObjectTypeAmount
) {
  uint16[] memory inputObjectTypeIds = new uint16[](2);
  inputObjectTypeIds[0] = inputObjectTypeId1.unwrap();
  inputObjectTypeIds[1] = inputObjectTypeId2.unwrap();

  uint16[] memory inputObjectTypeAmounts = new uint16[](2);
  inputObjectTypeAmounts[0] = inputObjectTypeAmount1;
  inputObjectTypeAmounts[1] = inputObjectTypeAmount2;

  // Form recipe id from input and output object type ids
  bytes32 recipeId = inputObjectTypeId1.unwrap() < inputObjectTypeId2.unwrap()
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
  ObjectTypeId inputObjectTypeId1,
  uint16 inputObjectTypeAmount1,
  ObjectTypeId inputObjectTypeId2,
  uint16 inputObjectTypeAmount2,
  ObjectTypeId outputObjectTypeId,
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
