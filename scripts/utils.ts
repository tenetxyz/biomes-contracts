import { getTableName } from "@latticexyz/store-sync/sqlite";
import { Hex } from "viem";

export function replacer(key, value) {
  if (value === undefined) {
    return "undefined";
  } else if (typeof value === "bigint") {
    return "BigInt:" + value.toString();
  } else if (value instanceof Map) {
    return { dataType: "Map", value: Array.from(value.entries()) };
  } else if (value instanceof Set) {
    return { dataType: "Set", value: Array.from(value) };
  } else if (value === Infinity) {
    return "Infinity";
  } else if (value === -Infinity) {
    return "-Infinity";
  } else {
    return value;
  }
}

export function reviver(key, value) {
  if (typeof value === "string") {
    if (value.startsWith("BigInt:")) {
      return BigInt(value.substring("BigInt:".length));
    } else if (value === "Infinity") {
      return Infinity;
    } else if (value === "-Infinity") {
      return -Infinity;
    } else if (value === "undefined") {
      return undefined;
    }
    return value;
  } else if (value && typeof value === "object") {
    if (value.dataType === "Map") {
      return new Map(value.value.map(([k, v]) => [k, JSON.parse(JSON.stringify(v, replacer), reviver)]));
    } else if (value.dataType === "Set") {
      return new Set(Array.from(value.value, (v) => JSON.parse(JSON.stringify(v, replacer), reviver)));
    } else {
      // For regular objects, recursively revive any nested structures
      for (const prop in value) {
        value[prop] = JSON.parse(JSON.stringify(value[prop], replacer), reviver);
      }
      return value;
    }
  }
  return value;
}

export function constructTableNameForQuery(
  tableNamespace: string,
  tableName: string,
  worldAddress: Hex,
  indexer: { type: string; url: string },
) {
  if (indexer.type === "sqlite") {
    return getTableName(worldAddress, tableNamespace, tableName);
  } else {
    return constructDozerTableName(tableNamespace, tableName);
  }
}

function constructDozerTableName(tableNamespace: string, tableName: string) {
  return tableNamespace ? `${tableNamespace}__${tableName}` : tableName;
}
