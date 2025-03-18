// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Vec3 } from "../Vec3.sol";
import { IForceFieldFragmentProgram } from "./IForceFieldFragmentProgram.sol";

import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";

// Interface for a force field program
interface IForceFieldProgram is IForceFieldFragmentProgram {
  function onPowered(EntityId callerEntityId, EntityId targetEntityId, uint16 fuelAmount) external;

  function onForceFieldHit(EntityId callerEntityId, EntityId targetEntityId) external;

  function onExpand(
    EntityId callerEntityId,
    EntityId targetEntityId,
    Vec3 fromFragmentCoord,
    Vec3 toFragmentCoord,
    bytes memory extraData
  ) external;

  function onContract(
    EntityId callerEntityId,
    EntityId targetEntityId,
    Vec3 fromFragmentCoord,
    Vec3 toFragmentCoord,
    bytes memory extraData
  ) external;
}
