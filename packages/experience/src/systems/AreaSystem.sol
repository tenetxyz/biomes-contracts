// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { Areas, AreasData } from "../codegen/tables/Areas.sol";
import { Area } from "../utils/AreaUtils.sol";

import { getExperienceAddress } from "../Utils.sol";

contract AreaSystem is System {
  function setArea(bytes32 areaId, string memory name, Area memory area) public {
    Areas.set(
      getExperienceAddress(_msgSender()),
      areaId,
      AreasData({
        name: name,
        lowerSouthwestCornerX: area.lowerSouthwestCorner.x,
        lowerSouthwestCornerY: area.lowerSouthwestCorner.y,
        lowerSouthwestCornerZ: area.lowerSouthwestCorner.z,
        sizeX: area.size.x,
        sizeY: area.size.y,
        sizeZ: area.size.z
      })
    );
  }

  function deleteArea(bytes32 areaId) public {
    Areas.deleteRecord(getExperienceAddress(_msgSender()), areaId);
  }
}
