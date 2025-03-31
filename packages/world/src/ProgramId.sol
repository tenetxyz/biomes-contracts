// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { WorldContextConsumerLib, WorldContextProviderLib } from "@latticexyz/world/src/WorldContext.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { revertWithBytes } from "@latticexyz/world/src/revertWithBytes.sol";

import { ObjectTypeId } from "./ObjectTypeId.sol";
import { ObjectAmount } from "./ObjectTypeLib.sol";
import { EntityId } from "./EntityId.sol";
import { Vec3 } from "./Vec3.sol";
import { IHooks } from "./IHooks.sol";
import { SAFE_PROGRAM_GAS } from "./Constants.sol";

type ProgramId is bytes32;

interface IProgram {
  function isProgramAllowed(
    EntityId caller,
    EntityId target,
    EntityId programmed,
    ProgramId newProgram,
    bytes memory extraData
  ) external view returns (bool);
}

library ProgramIdLib {
  function exists(ProgramId self) internal pure returns (bool) {
    return ProgramId.unwrap(self) != 0;
  }

  function toResourceId(ProgramId self) internal pure returns (ResourceId) {
    return ResourceId.wrap(ProgramId.unwrap(self));
  }

  function getAddress(ProgramId self) internal view returns (address) {
    if (!self.exists()) {
      return address(0);
    }
    (address programAddress, ) = Systems._get(self.toResourceId());
    return programAddress;
  }

  function call(ProgramId self, bytes memory callData) internal returns (bool, bytes memory) {
    // If no program set, allow the call
    address programAddress = self.getAddress();
    if (programAddress == address(0)) {
      return (true, "");
    }

    // If program is set, call it and return the result
    return
      WorldContextProviderLib.callWithContext({
        msgSender: address(0),
        msgValue: 0,
        target: programAddress,
        callData: callData
      });
  }

  function callOrRevert(ProgramId self, bytes memory callData) internal returns (bytes memory) {
    (bool success, bytes memory returnData) = self.call(callData);
    if (!success) {
      revertWithBytes(returnData);
    }
    return returnData;
  }

  function safeCall(ProgramId self, bytes memory data) internal view returns (bool, bytes memory) {
    address programAddress = self.getAddress();
    if (programAddress == address(0)) {
      return (true, "");
    }

    return
      programAddress.staticcall{ gas: SAFE_PROGRAM_GAS }(
        WorldContextProviderLib.appendContext({ callData: data, msgSender: address(0), msgValue: 0 })
      );
  }

  function staticcall(ProgramId self, bytes memory callData) internal view returns (bool, bytes memory) {
    // If no program set, allow the call
    address programAddress = self.getAddress();
    if (programAddress == address(0)) {
      return (true, "");
    }

    // If program is set, call it and return the result
    return
      WorldContextProviderLib.staticcallWithContext({
        msgSender: address(0),
        target: programAddress,
        callData: callData
      });
  }

  // Displays
  // TODO: describe format
  // function getDisplayURI(EntityId caller, EntityId target) external view returns (string memory);
}

using ProgramIdLib for ProgramId global;
