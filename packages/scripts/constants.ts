export const GRASS_OBJECT_TYPE_ID = 35;
import { resourceToHex } from "@latticexyz/common";

export const ACTIVATE_SYSTEM_ID = resourceToHex({ type: "system", namespace: "", name: "ActivateSystem" });
export const SPAWN_SYSTEM_ID = resourceToHex({ type: "system", namespace: "", name: "SpawnSystem" });
export const BUILD_SYSTEM_ID = resourceToHex({ type: "system", namespace: "", name: "BuildSystem" });
export const MINE_SYSTEM_ID = resourceToHex({ type: "system", namespace: "", name: "MineSystem" });
export const CRAFT_SYSTEM_ID = resourceToHex({ type: "system", namespace: "", name: "CraftSystem" });
export const DROP_SYSTEM_ID = resourceToHex({ type: "system", namespace: "", name: "DropSystem" });
export const EQUIP_SYSTEM_ID = resourceToHex({ type: "system", namespace: "", name: "EquipSystem" });
export const UNEQUIP_SYSTEM_ID = resourceToHex({ type: "system", namespace: "", name: "UnequipSystem" });
export const HIT_SYSTEM_ID = resourceToHex({ type: "system", namespace: "", name: "HitSystem" });
export const LOGIN_SYSTEM_ID = resourceToHex({ type: "system", namespace: "", name: "LoginSystem" });
export const LOGOFF_SYSTEM_ID = resourceToHex({ type: "system", namespace: "", name: "LogoffSystem" });
export const MOVE_SYSTEM_ID = resourceToHex({ type: "system", namespace: "", name: "MoveSystem" });
export const TRANSFER_SYSTEM_ID = resourceToHex({ type: "system", namespace: "", name: "TransferSystem" });
export const CHIP_SYSTEM_ID = resourceToHex({ type: "system", namespace: "", name: "ChipSystem" });

export const ALL_SYSTEM_IDS = [
  ACTIVATE_SYSTEM_ID,
  SPAWN_SYSTEM_ID,
  BUILD_SYSTEM_ID,
  MINE_SYSTEM_ID,
  CRAFT_SYSTEM_ID,
  DROP_SYSTEM_ID,
  EQUIP_SYSTEM_ID,
  UNEQUIP_SYSTEM_ID,
  HIT_SYSTEM_ID,
  LOGIN_SYSTEM_ID,
  LOGOFF_SYSTEM_ID,
  MOVE_SYSTEM_ID,
  TRANSFER_SYSTEM_ID,
  CHIP_SYSTEM_ID,
];

export const EMPTY_ADDRESS = "0x0000000000000000000000000000000000000000";
export const EMPTY_BYTES_32 = "0x0000000000000000000000000000000000000000000000000000000000000000";
