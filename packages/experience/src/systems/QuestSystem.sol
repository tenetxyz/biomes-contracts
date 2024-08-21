// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { BaseTriggerKind, LeafTriggerKind } from "../codegen/common.sol";
import { Quest, QuestData } from "../codegen/tables/Quest.sol";
import { BaseTrigger, BaseTriggerData } from "../codegen/tables/BaseTrigger.sol";
import { LeafTrigger, LeafTriggerData } from "../codegen/tables/LeafTrigger.sol";

contract QuestSystem is System {
  function addQuest(QuestData memory quest) public {
    bytes32 id = keccak256(abi.encodePacked(quest.nameId));
    require(Quest.getTriggerId(id) == bytes32(0), "QuestSystem: a quest with this id already exists");
    require(quest.triggerId != bytes32(0), "QuestSystem: triggerId must not be empty");
    require(bytes(quest.nameId).length > 0, "QuestSystem: nameId must not be empty");
    require(bytes(quest.displayName).length > 0, "QuestSystem: displayName must not be empty");
    require(
      BaseTrigger.getKind(quest.triggerId) != BaseTriggerKind.None ||
        LeafTrigger.getKind(quest.triggerId) != LeafTriggerKind.None,
      "QuestSystem: triggerId must be a valid trigger"
    );
    if (quest.unlockId != bytes32(0)) {
      require(
        BaseTrigger.getKind(quest.unlockId) != BaseTriggerKind.None ||
          LeafTrigger.getKind(quest.unlockId) != LeafTriggerKind.None,
        "QuestSystem: unlockId must be a valid trigger"
      );
    }

    Quest.set(id, quest);
  }

  // function addBaseTrigger(bytes32 id, BaseTriggerData memory data) public {
  //   BaseTrigger.set(id, data);
  // }
}
