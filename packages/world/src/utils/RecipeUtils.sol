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
function _setObjectOres(ObjectTypeId output, uint16[] memory inputs, uint16[] memory amounts) {
  for (uint256 i = 0; i < inputs.length; i++) {
    ObjectTypeId input = ObjectTypeId.wrap(inputs[i]);
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

  _setObjectOres(outputObjectTypeId, inputObjectTypeIds, inputObjectTypeAmounts);

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

  _setObjectOres(outputObjectTypeId, inputObjectTypeIds, inputObjectTypeAmounts);

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
