# Capped Resources

## Resource Types and Management

### 1. Ores

Ores follow a complete lifecycle with position tracking and respawning.

#### Mining Ores
- Ores initially exist as `AnyOre` blocks in the world
- When mined, they are collapsed into a specific ore type by choosing an ore at random weighted by availability
- Positions of mined ores are tracked using the ResourcePosition and ResourceCount so that they can be respawned
- The ResourceCount table is incremented for the specific ore type

#### Burning Ores
- When tools containing ores are burned (via `ObjectTypeLib.burnOres`), the ore resource is made available again
- ResourceCount is decreased for that specific ore
- BurnedResourceCount is increased for AnyOre category
- This creates a "pool" of ores that can respawn

#### Respawning Ores
- The NatureSystem handles respawning via `respawnResource`
- A random previously-mined position is selected
- If the position is valid (air block, no items), the ore can respawn
- ResourceCount, BurnedResourceCount, and position tracking are updated

### 2. Seeds

Seeds have a simpler approach focused on tracking quantities without position management.

#### Obtaining Seeds
- Seeds drop from mining certain blocks (e.g., WheatSeed from FescueGrass or Wheat)
- Drop probabilities are adjusted based on availability using a binomial distribution model
- ResourceCount is incremented when seeds are obtained
- No position tracking is needed for seeds

#### Using Seeds
- When seeds fully grow via FarmingSystem's `growSeed`
- ResourceCount is decremented, removing the seed from circulation
- No BurnedResourceCount modification
- No respawning mechanism for seeds

## Key Tables and Their Purpose

### ResourceCount
- **Purpose**: Tracks the current number of each resource type in circulation
- **Key**: ObjectTypeId (resource type)
- **Value**: count (how many of this resource exist)
- **Usage**: Used for cap enforcement and probability adjustments

### TotalResourceCount
- **Purpose**: Tracks the total resources mined over time (for position tracking)
- **Key**: ObjectTypeId (resource type)
- **Value**: count (total number mined)
- **Usage**: Only used for ores to maintain the position array

### ResourcePosition
- **Purpose**: Stores the positions where resources were mined
- **Key**: ObjectTypeId and index
- **Value**: Vec3 coordinates
- **Usage**: Used only for ores to enable respawning at previously mined locations

### BurnedResourceCount
- **Purpose**: Tracks resources that have been "burned" and can respawn
- **Key**: ObjectTypeId (resource type)
- **Value**: count (how many available to respawn)
- **Usage**: Used only for ores to maintain the respawn pool

### SeedGrowth
- **Purpose**: Tracks when seeds will be fully grown
- **Key**: EntityId (seed entity)
- **Value**: fullyGrownAt (timestamp)
- **Usage**: Used to determine when seeds can be grown into plants

## Resource Availability and Probabilities

### Ore Selection Logic
- When a player mines an `AnyOre`, a specific ore type is selected
- Selection probability is directly proportional to the remaining capacity
- Formula: `remaining = cap - mined`
- Higher remaining count = higher probability

### Seed Drop Logic
- Seeds follow a binomial probability distribution
- For example, Wheat has a chance to drop 0-3 seeds
- Base probabilities (for n=3, p=0.57):
  - 0 seeds: ~8%
  - 1 seed: ~31%
  - 2 seeds: ~41%
  - 3 seeds: ~20%
- These probabilities are adjusted based on remaining capacity
- For multiple seeds, a compound probability is calculated

## Implementation Details

### Key Functions

#### RandomResourceLib._trackPosition
```solidity
function _trackPosition(Vec3 coord, ObjectTypeId objectType) public {
  // Track resource position for mining/respawning
  uint256 totalResources = TotalResourceCount._get(objectType);
  ResourcePosition._set(objectType, totalResources, coord);
  TotalResourceCount._set(objectType, totalResources + 1);
}
```

#### NatureLib.selectObjectByWeight
```solidity
function selectObjectByWeight(ObjectAmount[] memory options, uint256[] memory weights, bytes32 seed)
  internal pure returns (ObjectAmount memory)
{
  uint256 selectedIndex = selectByWeight(weights, seed);
  return options[selectedIndex];
}
```

#### FarmingSystem.growSeed
```solidity
// When a seed grows, it's permanently removed from circulation
ResourceCount._set(objectTypeId, ResourceCount._get(objectTypeId) - 1);
```

#### ObjectTypeLib.burnOres
```solidity
function burnOres(ObjectTypeId self) internal {
  ObjectAmount memory ores = self.getOreAmount();
  ObjectTypeId objectTypeId = ores.objectTypeId;
  if (!objectTypeId.isNull()) {
    uint256 amount = ores.amount;
    // This increases the availability of the ores being burned
    ResourceCount._set(objectTypeId, ResourceCount._get(objectTypeId) - amount);
    // This allows the same amount of ores to respawn
    BurnedResourceCount._set(ObjectTypes.AnyOre, BurnedResourceCount._get(ObjectTypes.AnyOre) + amount);
  }
}
```

## Conceptual Model

### Resource Lifecycle

1. **Creation**
   - Ores: Exist in the world as `AnyOre`, collapse to specific types when mined
   - Seeds: Created as drops from mining certain blocks

2. **Circulation**
   - Resources enter player inventories
   - ResourceCount tracks total circulation

3. **Consumption**
   - Ores: Used to craft tools, re-enter system when tools are burned
   - Seeds: Permanently consumed when they grow into plants

4. **Respawning**
   - Ores: Can respawn at previously mined locations
   - Seeds: No respawning, only new drops based on probability

### Resource Caps

Resource caps provide natural limits to prevent infinite resources:

- As resources approach their cap, drop probabilities decrease
- For multi-resource drops (like 2-3 seeds), probability is reduced more aggressively
- This creates a balanced ecosystem where resources remain valuable but renewable

## System Interactions

- **MineSystem**: Handles resource extraction and tracking
- **FarmingSystem**: Handles seed growth and consumption
- **BuildSystem**: Handles seed placement
- **NatureSystem**: Handles ore respawning

This unified approach ensures resources can be mined, used, and (for ores) respawned in a sustainable ecosystem, preventing permanent depletion while still maintaining resource scarcity.
