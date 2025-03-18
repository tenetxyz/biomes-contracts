// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ProgramOnTransferData } from "../Types.sol";
import { IProgram } from "./IProgram.sol";

// Interface for a chest program
interface IChestProgram is IProgram {
  function onTransfer(ProgramOnTransferData memory transferContext) external payable;
}
