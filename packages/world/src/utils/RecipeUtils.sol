// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Recipes, RecipesData } from "../codegen/tables/Recipes.sol";

import { ObjectType, NullObjectType } from "../ObjectType.sol";

function createRecipe(
  ObjectType stationObjectType,
  ObjectType[] memory inputTypes,
  uint16[] memory inputAmounts,
  ObjectType[] memory outputTypes,
  uint16[] memory outputAmounts
) {
  bytes32 recipeId = hashInputs(stationObjectType, inputTypes, inputAmounts);

  uint16[] memory _outputTypes;
  assembly ("memory-safe") {
    _outputTypes := outputTypes
  }

  Recipes._set(recipeId, _outputTypes, outputAmounts);
}

function hashInputs(
  ObjectType stationObjectType,
  ObjectType[] memory inputTypes,
  uint16[] memory inputAmounts
) pure returns (bytes32) {
  return keccak256(abi.encode(stationObjectType, inputTypes, inputAmounts));
}

function createSingleInputWithStationRecipe(
  ObjectType stationObjectType,
  ObjectType inputObjectType,
  uint16 inputObjectTypeAmount,
  ObjectType outputObjectType,
  uint16 outputObjectTypeAmount
) {
  ObjectType[] memory inputTypes = new ObjectType[](1);
  inputTypes[0] = inputObjectType;
  uint16[] memory inputAmounts = new uint16[](1);
  inputAmounts[0] = inputObjectTypeAmount;

  ObjectType[] memory outputTypes = new ObjectType[](1);
  outputTypes[0] = outputObjectType;
  uint16[] memory outputAmounts = new uint16[](1);
  outputAmounts[0] = outputObjectTypeAmount;

  createRecipe(stationObjectType, inputTypes, inputAmounts, outputTypes, outputAmounts);
}

function createSingleInputRecipe(
  ObjectType inputObjectType,
  uint16 inputObjectTypeAmount,
  ObjectType outputObjectType,
  uint16 outputObjectTypeAmount
) {
  createSingleInputWithStationRecipe(
    NullObjectType,
    inputObjectType,
    inputObjectTypeAmount,
    outputObjectType,
    outputObjectTypeAmount
  );
}

function createDoubleInputWithStationRecipe(
  ObjectType stationObjectType,
  ObjectType inputObjectType1,
  uint16 inputObjectTypeAmount1,
  ObjectType inputObjectType2,
  uint16 inputObjectTypeAmount2,
  ObjectType outputObjectType,
  uint16 outputObjectTypeAmount
) {
  ObjectType[] memory inputTypes = new ObjectType[](2);
  inputTypes[0] = inputObjectType1;
  inputTypes[1] = inputObjectType2;

  uint16[] memory inputAmounts = new uint16[](2);
  inputAmounts[0] = inputObjectTypeAmount1;
  inputAmounts[1] = inputObjectTypeAmount2;

  ObjectType[] memory outputTypes = new ObjectType[](1);
  outputTypes[0] = outputObjectType;
  uint16[] memory outputAmounts = new uint16[](1);
  outputAmounts[0] = outputObjectTypeAmount;

  createRecipe(stationObjectType, inputTypes, inputAmounts, outputTypes, outputAmounts);
}

function createDoubleInputRecipe(
  ObjectType inputObjectType1,
  uint16 inputObjectTypeAmount1,
  ObjectType inputObjectType2,
  uint16 inputObjectTypeAmount2,
  ObjectType outputObjectType,
  uint16 outputObjectTypeAmount
) {
  createDoubleInputWithStationRecipe(
    NullObjectType,
    inputObjectType1,
    inputObjectTypeAmount1,
    inputObjectType2,
    inputObjectTypeAmount2,
    outputObjectType,
    outputObjectTypeAmount
  );
}
