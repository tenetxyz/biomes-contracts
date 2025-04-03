# DUST

This repo hosts the contracts for the DUST world.

### Random Resource Drops

DUST implements a resource management mechanism that controls how certain natural resources are collected, tracked, and respawned.

It is designed to create a balanced ecosystem where resources remain valuable but renewable.

#### Ore Collection
- Ores originally exist as generic `AnyOre` blocks in the world
- When mined, a specific ore type is selected based on availability
- The system tracks where ores were mined for potential respawning
- Selection probability is directly proportional to remaining capacity (cap minus current amount in circulation)

#### Seed Collection
- Seeds drop when mining certain plants (e.g., wheat seeds from wheat or grass)
- Drop chances follow a probability distribution that adjusts based on availability
- For example, wheat can drop 0-3 seeds with varying probabilities
- As seeds approach their cap, drop probabilities decrease accordingly

#### Resource Availability
- Resources drops that depend on randomness have caps to prevent infinite accumulation
- The drop probabilities are always scaled to the remaining amount of resources in nature
- This creates natural scarcity while allowing renewable resources

#### Resource Circulation
- Ore lifecycle: Mining → Usage in tools → Tool burning → Respawning
- Seed lifecycle: Drop from plants → Planting → Growing → Harvesting new crops
- The system tracks resource quantities to maintain balance

#### Tables and Tracking

The game uses several key tables to manage resources:

- **ResourceCount**: Tracks the current quantity of each resource type in circulation and is used for all probability calculations
- **ResourcePosition**: Stores positions where ores were mined to enable respawning
- **BurnedResourceCount**: Tracks resources ready for respawning (primarily ores)
- **SeedGrowth**: Manages the growth timeline for planted seeds

