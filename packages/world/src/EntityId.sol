// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";

import { PlayerStatus } from "./codegen/tables/PlayerStatus.sol";
import { ReversePlayer } from "./codegen/tables/ReversePlayer.sol";
import { Program } from "./codegen/tables/Program.sol";
import { ObjectType } from "./codegen/tables/ObjectType.sol";
import { BaseEntity } from "./codegen/tables/BaseEntity.sol";
import { Energy, EnergyData } from "./codegen/tables/Energy.sol";

import { MovablePosition, Position } from "./utils/Vec3Storage.sol";
import { updatePlayerEnergy, updateMachineEnergy } from "./utils/EnergyUtils.sol";
import { getForceField } from "./utils/ForceFieldUtils.sol";

import { checkWorldStatus } from "./Utils.sol";
import { ObjectTypeId } from "./ObjectTypeId.sol";
import { ObjectTypes } from "./ObjectTypes.sol";
import { ObjectTypeLib } from "./ObjectTypeLib.sol";
import { Vec3 } from "./Vec3.sol";
import { MAX_ENTITY_INFLUENCE_HALF_WIDTH } from "./Constants.sol";

using ObjectTypeLib for ObjectTypeId;

type EntityId is bytes32;

library EntityIdLib {
  // We need to use this internal library function in order to obtain the msg.sig and msg.sender
  function activate(EntityId self) internal returns (EnergyData memory) {
    address caller = WorldContextConsumerLib._msgSender();
    return ActivateLib._activate(self, caller, msg.sig);
  }

  function requireCallerAllowed(EntityId self, address caller, ObjectTypeId objectTypeId) internal view {
    if (objectTypeId == ObjectTypes.Player) {
      require(caller == ReversePlayer._get(self), "Caller not allowed");
    } else {
      address programAddress = self.getProgramAddress();
      require(caller == programAddress, "Caller not allowed");
    }
  }

  function requireCallerAllowed(EntityId self, address sender) internal view {
    ObjectTypeId objectTypeId = ObjectType.get(self);
    requireCallerAllowed(self, sender, objectTypeId);
  }

  function baseEntityId(EntityId self) internal view returns (EntityId) {
    EntityId base = BaseEntity._get(self);
    return EntityId.unwrap(base) == 0 ? self : base;
  }

  // TODO: add pipe connections
  // TODO: should non-player entities have a range != to players?
  function requireConnected(EntityId self, EntityId other) internal view returns (Vec3, Vec3) {
    Vec3 otherCoord = other.getPosition();
    return requireConnected(self, otherCoord);
  }

  function requireConnected(EntityId self, Vec3 otherCoord) internal view returns (Vec3, Vec3) {
    Vec3 selfCoord = self.getPosition();
    require(selfCoord.inSurroundingCube(otherCoord, MAX_ENTITY_INFLUENCE_HALF_WIDTH), "Entity is too far");
    return (selfCoord, otherCoord);
  }

  function getPosition(EntityId self) internal view returns (Vec3) {
    return ObjectType._get(self).isMovable() ? MovablePosition._get(self) : Position._get(self);
  }

  function getProgramAddress(EntityId entityId) internal view returns (address) {
    ResourceId programSystemId = entityId.getProgram();
    (address programAddress, ) = Systems._get(programSystemId);
    return programAddress;
  }

  function getProgram(EntityId entityId) internal view returns (ResourceId) {
    return Program._getProgramSystemId(entityId);
  }

  function exists(EntityId self) internal pure returns (bool) {
    return EntityId.unwrap(self) != bytes32(0);
  }

  function unwrap(EntityId self) internal pure returns (bytes32) {
    return EntityId.unwrap(self);
  }
}

function eq(EntityId self, EntityId other) pure returns (bool) {
  return EntityId.unwrap(self) == EntityId.unwrap(other);
}

function neq(EntityId self, EntityId other) pure returns (bool) {
  return EntityId.unwrap(self) != EntityId.unwrap(other);
}

library ActivateLib {
  function _activate(EntityId self, address caller, bytes4 sig) public returns (EnergyData memory) {
    checkWorldStatus();

    ObjectTypeId objectTypeId = ObjectType._get(self);
    require(objectTypeId.isActionAllowed(sig), "Action not allowed");

    self.requireCallerAllowed(caller, objectTypeId);

    // TODO: do we want to support chips for players?
    EnergyData memory energyData;
    if (objectTypeId == ObjectTypes.Player) {
      require(!PlayerStatus._getBedEntityId(self).exists(), "Player is sleeping");
      energyData = updatePlayerEnergy(self);
    } else {
      EntityId forceFieldEntityId;
      if (objectTypeId == ObjectTypes.ForceField) {
        forceFieldEntityId = self;
      } else {
        (forceFieldEntityId, ) = getForceField(self.getPosition());
      }

      (energyData, ) = updateMachineEnergy(forceFieldEntityId);
    }

    require(energyData.energy > 0, "Entity has no energy");

    return energyData;
  }
}

using EntityIdLib for EntityId global;
using { eq as ==, neq as != } for EntityId global;
