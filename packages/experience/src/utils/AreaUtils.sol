// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { Areas, AreasData } from "../codegen/tables/Areas.sol";
import { getEntityAtCoord, getObjectType } from "./EntityUtils.sol";

struct Area {
  VoxelCoord lowerSouthwestCorner;
  VoxelCoord size;
}

function getArea(address experience, bytes32 areaId) view returns (Area memory) {
  AreasData memory areaData = Areas.get(experience, areaId);

  return
    Area({
      lowerSouthwestCorner: VoxelCoord(
        areaData.lowerSouthwestCornerX,
        areaData.lowerSouthwestCornerY,
        areaData.lowerSouthwestCornerZ
      ),
      size: VoxelCoord(areaData.sizeX, areaData.sizeY, areaData.sizeZ)
    });
}

function setArea(address experience, bytes32 areaId, string memory name, Area memory area) {
  Areas.set(
    experience,
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

function insideArea(Area memory area, VoxelCoord memory baseWorldCoord) pure returns (bool) {
  VoxelCoord memory topNortheastCorner = VoxelCoord(
    area.lowerSouthwestCorner.x + area.size.x,
    area.lowerSouthwestCorner.y + area.size.y,
    area.lowerSouthwestCorner.z + area.size.z
  );

  if (
    baseWorldCoord.x >= area.lowerSouthwestCorner.x &&
    baseWorldCoord.x < topNortheastCorner.x &&
    baseWorldCoord.y >= area.lowerSouthwestCorner.y &&
    baseWorldCoord.y < topNortheastCorner.y &&
    baseWorldCoord.z >= area.lowerSouthwestCorner.z &&
    baseWorldCoord.z < topNortheastCorner.z
  ) {
    return true;
  }

  return false;
}

function insideAreaIgnoreY(Area memory area, VoxelCoord memory baseWorldCoord) pure returns (bool) {
  VoxelCoord memory topNortheastCorner = VoxelCoord(
    area.lowerSouthwestCorner.x + area.size.x,
    area.lowerSouthwestCorner.y + area.size.y,
    area.lowerSouthwestCorner.z + area.size.z
  );

  if (
    baseWorldCoord.x >= area.lowerSouthwestCorner.x &&
    baseWorldCoord.x < topNortheastCorner.x &&
    baseWorldCoord.z >= area.lowerSouthwestCorner.z &&
    baseWorldCoord.z < topNortheastCorner.z
  ) {
    return true;
  }

  return false;
}

function getEntitiesInArea(Area memory area, uint8 objectTypeId) view returns (bytes32[] memory) {
  VoxelCoord memory lowerSouthwestCorner = area.lowerSouthwestCorner;
  VoxelCoord memory size = area.size;

  uint256 maxNumEntities = uint256(int256(size.x)) * uint256(int256(size.y)) * uint256(int256(size.z));
  bytes32[] memory maxEntityIds = new bytes32[](maxNumEntities);

  uint256 numFound = 0;

  for (int16 x = lowerSouthwestCorner.x; x < lowerSouthwestCorner.x + size.x; x++) {
    for (int16 y = lowerSouthwestCorner.y; y < lowerSouthwestCorner.y + size.y; y++) {
      for (int16 z = lowerSouthwestCorner.z; z < lowerSouthwestCorner.z + size.z; z++) {
        bytes32 entityId = getEntityAtCoord(VoxelCoord(x, y, z));

        if (entityId != bytes32(0) && getObjectType(entityId) == objectTypeId) {
          maxEntityIds[numFound] = entityId;
          numFound++;
        }
      }
    }
  }

  bytes32[] memory entityIds = new bytes32[](numFound);
  for (uint256 i = 0; i < numFound; i++) {
    entityIds[i] = maxEntityIds[i];
  }

  return entityIds;
}
