import { IStore } from "@latticexyz/store/src/IStore.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Health, HealthData } from "../codegen/tables/Health.sol";
import { Stamina, StaminaData } from "../codegen/tables/Stamina.sol";
import { Inventory } from "../codegen/tables/Inventory.sol";
import { ReverseInventory } from "../codegen/tables/ReverseInventory.sol";
import { InventorySlots } from "../codegen/tables/InventorySlots.sol";
import { InventoryCount } from "../codegen/tables/InventoryCount.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { ItemMetadata } from "../codegen/tables/ItemMetadata.sol";
import { Recipes, RecipesData } from "../codegen/tables/Recipes.sol";

import { positionDataToVoxelCoord } from "../Utils.sol";

function getPosition(address worldAddress, bytes32 entityId) view returns (VoxelCoord memory) {
  return positionDataToVoxelCoord(Position.get(IStore(worldAddress), entityId));
}

function getObjectType(address worldAddress, bytes32 entityId) view returns (bytes32) {
  return ObjectType.get(IStore(worldAddress), entityId);
}

function getIsPlayer(address worldAddress, bytes32 objectTypeId) view returns (bool) {
  return ObjectTypeMetadata.getIsPlayer(IStore(worldAddress), objectTypeId);
}

function getIsBlock(address worldAddress, bytes32 objectTypeId) view returns (bool) {
  return ObjectTypeMetadata.getIsBlock(IStore(worldAddress), objectTypeId);
}

function getMass(address worldAddress, bytes32 objectTypeId) view returns (uint16) {
  return ObjectTypeMetadata.getMass(IStore(worldAddress), objectTypeId);
}

function getStackable(address worldAddress, bytes32 objectTypeId) view returns (uint8) {
  return ObjectTypeMetadata.getStackable(IStore(worldAddress), objectTypeId);
}

function getDamage(address worldAddress, bytes32 objectTypeId) view returns (uint16) {
  return ObjectTypeMetadata.getDamage(IStore(worldAddress), objectTypeId);
}

function getDurability(address worldAddress, bytes32 objectTypeId) view returns (uint24) {
  return ObjectTypeMetadata.getDurability(IStore(worldAddress), objectTypeId);
}

function getHardness(address worldAddress, bytes32 objectTypeId) view returns (uint16) {
  return ObjectTypeMetadata.getHardness(IStore(worldAddress), objectTypeId);
}

function getEntityFromPlayer(address worldAddress, address playerAddress) view returns (bytes32) {
  return Player.getEntityId(IStore(worldAddress), playerAddress);
}

function getPlayerFromEntity(address worldAddress, bytes32 entityId) view returns (address) {
  return ReversePlayer.getPlayer(IStore(worldAddress), entityId);
}

function getEquipped(address worldAddress, bytes32 playerEntityId) view returns (bytes32) {
  return Equipped.get(IStore(worldAddress), playerEntityId);
}

function getHealth(address worldAddress, bytes32 playerEntityId) view returns (uint16) {
  return Health.getHealth(IStore(worldAddress), playerEntityId);
}

function getStamina(address worldAddress, bytes32 playerEntityId) view returns (uint32) {
  return Stamina.getStamina(IStore(worldAddress), playerEntityId);
}

function getIsLoggedOff(address worldAddress, bytes32 playerEntityId) view returns (bool) {
  return PlayerMetadata.getIsLoggedOff(IStore(worldAddress), playerEntityId);
}

function getLastMoveBlock(address worldAddress, bytes32 playerEntityId) view returns (uint256) {
  return PlayerMetadata.getLastMoveBlock(IStore(worldAddress), playerEntityId);
}

function getLastHitTime(address worldAddress, bytes32 playerEntityId) view returns (uint256) {
  return PlayerMetadata.getLastHitTime(IStore(worldAddress), playerEntityId);
}

function getInventory(address worldAddress, bytes32 playerEntityId) view returns (bytes32[] memory) {
  return ReverseInventory.getEntityIds(IStore(worldAddress), playerEntityId);
}

function getCount(address worldAddress, bytes32 playerEntityId, bytes32 objectTypeId) view returns (uint16) {
  return InventoryCount.getCount(IStore(worldAddress), playerEntityId, objectTypeId);
}

function getNumSlotsUsed(address worldAddress, bytes32 playerEntityId) view returns (uint16) {
  return InventorySlots.getNumSlotsUsed(IStore(worldAddress), playerEntityId);
}

function getNumUsesLeft(address worldAddress, bytes32 toolEntityId) view returns (uint24) {
  return ItemMetadata.getNumUsesLeft(IStore(worldAddress), toolEntityId);
}

function getEntityAtCoord(address worldAddress, VoxelCoord memory coord) view returns (bytes32) {
  return ReversePosition.getEntityId(IStore(worldAddress), coord.x, coord.y, coord.z);
}

function getEntitiesInArea(
  address worldAddress,
  VoxelCoord memory lowerSouthwestCorner,
  VoxelCoord memory size,
  bytes32 objectTypeId
) view returns (bytes32[] memory) {
  uint256 maxNumEntities = uint256(int256(size.x)) * uint256(int256(size.y)) * uint256(int256(size.z));
  bytes32[] memory maxEntityIds = new bytes32[](maxNumEntities);

  uint256 numFound = 0;

  for (int32 x = lowerSouthwestCorner.x; x < lowerSouthwestCorner.x + size.x; x++) {
    for (int32 y = lowerSouthwestCorner.y; y < lowerSouthwestCorner.y + size.y; y++) {
      for (int32 z = lowerSouthwestCorner.z; z < lowerSouthwestCorner.z + size.z; z++) {
        bytes32 entityId = getEntityAtCoord(worldAddress, VoxelCoord(x, y, z));

        if (entityId != bytes32(0) && getObjectType(worldAddress, entityId) == objectTypeId) {
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
