// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Chip } from "../codegen/tables/Chip.sol";

import { DisplayContent } from "../Types.sol";
import { IDisplayChip } from "../prototypes/IDisplayChip.sol";

contract DisplaySystem is System {
  function getDisplayContent(bytes32 entityId) public view returns (DisplayContent memory) {
    require(entityId != bytes32(0), "DisplaySystem: entity does not exist");

    bytes32 baseEntityId = BaseEntity._get(entityId);
    baseEntityId = baseEntityId == bytes32(0) ? entityId : baseEntityId;

    address chipAddress = Chip.getChipAddress(baseEntityId);
    return IDisplayChip(chipAddress).getDisplayContent(baseEntityId);
  }
}
