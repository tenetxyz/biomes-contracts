// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { Assets } from "../codegen/tables/Assets.sol";
import { ResourceType } from "../codegen/common.sol";

contract AssetsSystem is System {
  function setAsset(address asset, ResourceType assetType) public {
    Assets.set(_msgSender(), asset, assetType);
  }

  function deleteAsset(address asset) public {
    Assets.deleteRecord(_msgSender(), asset);
  }
}
