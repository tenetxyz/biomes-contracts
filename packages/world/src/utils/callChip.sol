// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { WorldContextConsumerLib, WorldContextProviderLib } from "@latticexyz/world/src/WorldContext.sol";
import { revertWithBytes } from "@latticexyz/world/src/revertWithBytes.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { Chip } from "../codegen/tables/Chip.sol";
import { EntityId } from "../EntityId.sol";

function callChip(EntityId entityId, bytes memory data) returns (bytes memory) {
  ResourceId chipSystemId = Chip._get(entityId);
  require(chipSystemId.unwrap() != 0, "Entity does not have an attached chip");

  (address chipAddress, ) = Systems.get(chipSystemId);

  (bool success, bytes memory returnData) = WorldContextProviderLib.callWithContext(
    WorldContextConsumerLib._msgSender(),
    WorldContextConsumerLib._msgValue(),
    chipAddress,
    data
  );

  if (!success) {
    revertWithBytes(returnData);
  }

  return returnData;
}
