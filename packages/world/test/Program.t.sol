// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { console } from "forge-std/console.sol";

import { EntityId } from "../src/EntityId.sol";

import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { LocalEnergyPool } from "../src/codegen/tables/LocalEnergyPool.sol";

import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { OreCommitment } from "../src/codegen/tables/OreCommitment.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { Position } from "../src/codegen/tables/Position.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";

import { TotalBurnedOreCount } from "../src/codegen/tables/TotalBurnedOreCount.sol";
import { WorldStatus } from "../src/codegen/tables/WorldStatus.sol";
import { DustTest } from "./DustTest.sol";

import { CHUNK_SIZE } from "../src/Constants.sol";
import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectTypeLib } from "../src/ObjectTypeLib.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";

import { Vec3 } from "../src/Vec3.sol";
import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { TestUtils } from "./utils/TestUtils.sol";

contract ProgramTest is DustTest {
  using ObjectTypeLib for ObjectTypeId;

  function testMineFailsIfProgramAttached() public {
    vm.skip(true, "TODO");
  }

  function testTransferWithProgram() public {
    vm.skip(true, "TODO");
  }

  function testTransferFailsIfNotAllowedByProgram() public {
    vm.skip(true, "TODO");
  }

  function testTransferFailsIfForceFieldNotEnoughEnergy() public {
    vm.skip(true, "TODO");
  }
}
