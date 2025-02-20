// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Recipes, RecipesData } from "../codegen/tables/Recipes.sol";
import { ObjectTypeOres } from "../codegen/tables/ObjectTypeOres.sol";
import { ObjectTypeOreAmount } from "../codegen/tables/ObjectTypeOreAmount.sol";

import { ObjectTypeId, NullObjectTypeId } from "../ObjectTypeIds.sol";

/// @dev Helper function to add ore amount to an output and track it in the ores array if new
function _addOreToOutput(ObjectTypeId output, ObjectTypeId oreType, uint16 amount) {
  uint16 existingAmount = ObjectTypeOreAmount._get(output, oreType);
  ObjectTypeOreAmount._set(output, oreType, existingAmount + amount);
  if (existingAmount == 0) {
    ObjectTypeOres._push(output, oreType.unwrap());
  }
}

/// @dev Sets the corresponding ore amount for each input. It should only be called for single output recipes.
function _setObjectOres(ObjectTypeId output, ObjectTypeId[] memory inputs, uint16[] memory amounts) {
  for (uint256 i = 0; i < inputs.length; i++) {
    ObjectTypeId input = inputs[i];
    uint16 inputAmount = amounts[i];

    if (input.isOre()) {
      // Direct ore input
      _addOreToOutput(output, input, inputAmount);
    } else {
      // Check if this input has its own ore composition
      uint16[] memory inputOres = ObjectTypeOres._get(input);
      for (uint256 j = 0; j < inputOres.length; j++) {
        ObjectTypeId oreType = ObjectTypeId.wrap(inputOres[j]);
        // Get the ore amount from the input and multiply by the input amount
        uint16 oreAmountPerInput = ObjectTypeOreAmount._get(input, oreType);
        uint16 totalOreAmount = oreAmountPerInput * inputAmount;

        _addOreToOutput(output, oreType, totalOreAmount);
      }
    }
  }
}

function createRecipe(
  ObjectTypeId stationObjectTypeId,
  ObjectTypeId[] memory inputTypes,
  uint16[] memory inputAmounts,
  ObjectTypeId[] memory outputTypes,
  uint16[] memory outputAmounts
) {
  bytes32 recipeId = hashInputs(stationObjectTypeId, inputTypes, inputAmounts);

  uint16[] memory _outputTypes;
  assembly ("memory-safe") {
    _outputTypes := outputTypes
  }

  Recipes._set(recipeId, _outputTypes, outputAmounts);
}

function hashInputs(
  ObjectTypeId stationObjectTypeId,
  ObjectTypeId[] memory inputTypes,
  uint16[] memory inputAmounts
) pure returns (bytes32) {
  return keccak256(abi.encode(stationObjectTypeId, inputTypes, inputAmounts));
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

  _setObjectOres(outputObjectTypeId, inputTypes, inputAmounts);

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
  ObjectTypeId[] memory inputTypes = new ObjectTypeId[](2);
  inputTypes[0] = inputObjectTypeId1;
  inputTypes[1] = inputObjectTypeId2;

  uint16[] memory inputAmounts = new uint16[](2);
  inputAmounts[0] = inputObjectTypeAmount1;
  inputAmounts[1] = inputObjectTypeAmount2;

  _setObjectOres(outputObjectTypeId, inputTypes, inputAmounts);

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
    NullObjectTypeId,
    inputObjectTypeId1,
    inputObjectTypeAmount1,
    inputObjectTypeId2,
    inputObjectTypeAmount2,
    outputObjectTypeId,
    outputObjectTypeAmount
  );
}
