// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { BiomesTest, console } from "./BiomesTest.sol";

import { ExploredChunk, ExploredChunkByIndex, ForceField, LocalEnergyPool, ReversePosition, Position } from "../src/utils/Vec3Storage.sol";

import { EntityId } from "../src/EntityId.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";

contract Vec3Test is BiomesTest {
  function testVec3ToEntity() public {
    EntityId entityId = randomEntityId();
    Vec3 vec = vec3(1, 2, 3);

    Position.set(entityId, vec);
    Vec3 stored = Position.get(entityId);
    assertEq(vec, stored, "Vec3s do not match");
  }

  function testUint128ToVec3() public {
    Vec3 vec = vec3(1, 2, 3);
    uint128 value = 123;
    LocalEnergyPool.set(vec, value);
    uint128 storedValue = LocalEnergyPool.get(vec);
    assertEq(value, storedValue, "Values do not match");
  }
}
