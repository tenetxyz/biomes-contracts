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

type ProgramId is bytes32;

library ProgramIdLib {
  function unwrap(ProgramId self) internal pure returns (bytes32) {
    return ProgramId.unwrap(self);
  }

  function exists(ProgramId self) internal pure returns (bool) {
    return self.unwrap() != 0;
  }

  function toResourceId(ProgramId self) internal pure returns (ResourceId) {
    return ResourceId.wrap(self.unwrap());
  }

  function getAddress(ProgramId self) internal view returns (address) {
    if (!self.exists()) {
      return address(0);
    }
    (address programAddress, ) = Systems._get(self.toResourceId());
    return programAddress;
  }

  function call(ProgramId self, bytes memory hook, uint256 gas) internal returns (bool, bytes memory) {
    // If no program set, allow the call
    address programAddress = self.getAddress();
    if (programAddress == address(0)) {
      return (true, "");
    }

    return programAddress.call{ gas: gas }(_hookContext(hook));
  }

  function call(ProgramId self, bytes memory hook) internal returns (bool, bytes memory) {
    address programAddress = self.getAddress();
    if (programAddress == address(0)) {
      return (true, "");
    }

    return programAddress.call(_hookContext(hook));
  }

  function callOrRevert(ProgramId self, bytes memory callData) internal returns (bytes memory) {
    (bool success, bytes memory returnData) = self.call(callData);
    if (!success) {
      revertWithBytes(returnData);
    }
    return returnData;
  }

  function staticcall(ProgramId self, bytes memory hook) internal view returns (bool, bytes memory) {
    // If no program set, allow the call
    address programAddress = self.getAddress();
    if (programAddress == address(0)) {
      return (true, "");
    }

    // If program is set, call it and return the result
    return programAddress.staticcall(_hookContext(hook));
  }

  function staticcallOrRevert(ProgramId self, bytes memory callData) internal view returns (bytes memory) {
    (bool success, bytes memory returnData) = self.staticcall(callData);
    if (!success) {
      revertWithBytes(returnData);
    }
    return returnData;
  }

  function _hookContext(bytes memory hook) private pure returns (bytes memory) {
    return WorldContextProviderLib.appendContext({ callData: hook, msgSender: address(0), msgValue: 0 });
  }
}

function eq(ProgramId a, ProgramId b) pure returns (bool) {
  return a.unwrap() == b.unwrap();
}

using { eq as == } for ProgramId global;
using ProgramIdLib for ProgramId global;
