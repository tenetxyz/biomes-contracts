// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

enum ActionType {
  None,
  Build,
  Mine,
  Move,
  Craft,
  Drop,
  Pickup,
  Transfer,
  Equip,
  Unequip,
  Spawn,
  Sleep,
  Wakeup,
  PowerMachine,
  HitMachine,
  AttachChip,
  DetachChip,
  InitiateOreReveal,
  RevealOre,
  ExpandForceField
}

enum DisplayContentType {
  None,
  Text,
  Image
}

enum Direction {
  PositiveX,
  NegativeX,
  PositiveY,
  NegativeY,
  PositiveZ,
  NegativeZ,
  PositiveXPositiveY,
  PositiveXNegativeY,
  NegativeXPositiveY,
  NegativeXNegativeY,
  PositiveXPositiveZ,
  PositiveXNegativeZ,
  NegativeXPositiveZ,
  NegativeXNegativeZ,
  PositiveYPositiveZ,
  PositiveYNegativeZ,
  NegativeYPositiveZ,
  NegativeYNegativeZ,
  PositiveXPositiveYPositiveZ,
  PositiveXPositiveYNegativeZ,
  PositiveXNegativeYPositiveZ,
  PositiveXNegativeYNegativeZ,
  NegativeXPositiveYPositiveZ,
  NegativeXPositiveYNegativeZ,
  NegativeXNegativeYPositiveZ,
  NegativeXNegativeYNegativeZ
}
