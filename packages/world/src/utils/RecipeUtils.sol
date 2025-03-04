// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Recipes, RecipesData } from "../codegen/tables/Recipes.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";

function createRecipe(
  ObjectTypeId stationObjectTypeId,
  ObjectTypeId[] memory inputTypes,
  uint16[] memory inputAmounts,
  ObjectTypeId[] memory outputTypes,
  uint16[] memory outputAmounts
) {
  bytes32 recipeId = hashRecipe(stationObjectTypeId, inputTypes, inputAmounts, outputTypes, outputAmounts);

  uint16[] memory _inputTypes;
  assembly ("memory-safe") {
    _inputTypes := inputTypes
  }

  uint16[] memory _outputTypes;
  assembly ("memory-safe") {
    _outputTypes := outputTypes
  }

  Recipes._set(recipeId, stationObjectTypeId, _inputTypes, inputAmounts, _outputTypes, outputAmounts);
}

function hashRecipe(
  ObjectTypeId stationObjectTypeId,
  ObjectTypeId[] memory inputTypes,
  uint16[] memory inputAmounts,
  ObjectTypeId[] memory outputTypes,
  uint16[] memory outputAmounts
) pure returns (bytes32) {
  return keccak256(abi.encode(stationObjectTypeId, inputTypes, inputAmounts, outputTypes, outputAmounts));
}

function createSingleInputWithStationRecipe(
  ObjectTypeId stationObjectTypeId,
  ObjectTypeId inputObjectTypeId,
  uint16 inputObjectTypeAmount,
  ObjectTypeId outputObjectTypeId,
  uint16 outputObjectTypeAmount
) {
  ObjectTypeId[] memory inputTypes = new ObjectTypeId[](1);
  inputTypes[0] = inputObjectTypeId;
  uint16[] memory inputAmounts = new uint16[](1);
  inputAmounts[0] = inputObjectTypeAmount;

  ObjectTypeId[] memory outputTypes = new ObjectTypeId[](1);
  outputTypes[0] = outputObjectTypeId;
  uint16[] memory outputAmounts = new uint16[](1);
  outputAmounts[0] = outputObjectTypeAmount;

  createRecipe(stationObjectTypeId, inputTypes, inputAmounts, outputTypes, outputAmounts);
}

function createSingleInputRecipe(
  ObjectTypeId inputObjectTypeId,
  uint16 inputObjectTypeAmount,
  ObjectTypeId outputObjectTypeId,
  uint16 outputObjectTypeAmount
) {
  createSingleInputWithStationRecipe(
    ObjectTypes.Null,
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
  ObjectTypeId[] memory inputTypes = new ObjectTypeId[](2);
  inputTypes[0] = inputObjectTypeId1;
  inputTypes[1] = inputObjectTypeId2;

  uint16[] memory inputAmounts = new uint16[](2);
  inputAmounts[0] = inputObjectTypeAmount1;
  inputAmounts[1] = inputObjectTypeAmount2;

  ObjectTypeId[] memory outputTypes = new ObjectTypeId[](1);
  outputTypes[0] = outputObjectTypeId;
  uint16[] memory outputAmounts = new uint16[](1);
  outputAmounts[0] = outputObjectTypeAmount;

  createRecipe(stationObjectTypeId, inputTypes, inputAmounts, outputTypes, outputAmounts);
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
    ObjectTypes.Null,
    inputObjectTypeId1,
    inputObjectTypeAmount1,
    inputObjectTypeId2,
    inputObjectTypeAmount2,
    outputObjectTypeId,
    outputObjectTypeAmount
  );
}
