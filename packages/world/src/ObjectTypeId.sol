// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

type ObjectTypeId is uint16;

function eq(ObjectTypeId self, ObjectTypeId other) pure returns (bool) {
  return ObjectTypeId.unwrap(self) == ObjectTypeId.unwrap(other);
}

function neq(ObjectTypeId self, ObjectTypeId other) pure returns (bool) {
  return ObjectTypeId.unwrap(self) != ObjectTypeId.unwrap(other);
}

using { eq as ==, neq as != } for ObjectTypeId global;
