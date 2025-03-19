// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Vec3 } from "../Vec3.sol";
import { IProgram } from "./IProgram.sol";

import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";

// Interface for a force field program
interface IForceFieldFragmentProgram is IProgram {
  function onBuild(
    EntityId targetEntityId,
    EntityId callerEntityId,
    ObjectTypeId objectTypeId,
    Vec3 coord,
    bytes memory extraData
  ) external payable;

  function onMine(
    EntityId targetEntityId,
    EntityId callerEntityId,
    ObjectTypeId objectTypeId,
    Vec3 coord,
    bytes memory extraData
  ) external payable;

  function onProgramAttached(
    EntityId callerEntityId,
    EntityId targetEntityId,
    EntityId attachedToEntityId,
    bytes memory extraData
  ) external;

  function onProgramDetached(
    EntityId callerEntityId,
    EntityId targetEntityId,
    EntityId detachedFromEntityId,
    bytes memory extraData
  ) external;
}
