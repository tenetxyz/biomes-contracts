// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";
import { ROOT_NAMESPACE_ID } from "@latticexyz/world/src/constants.sol";

import { BlockHash } from "../../codegen/tables/BlockHash.sol";
import { BlockPrevrandao } from "../../codegen/tables/BlockPrevrandao.sol";
import { ORACLE_ADDRESS } from "../../Constants.sol";

contract OracleSystem is System {
  function setBlockHash(uint256 blockNumber, bytes32 blockHash) public {
    require(_msgSender() == ORACLE_ADDRESS, "Only the oracle can set the block hash");
    BlockHash._set(blockNumber, blockHash);
  }

  function setBlockPrevrandao(uint256 blockNumber, uint256 blockPrevrandao) public {
    require(_msgSender() == ORACLE_ADDRESS, "Only the oracle can set the block prevrandao");
    BlockPrevrandao._set(blockNumber, blockPrevrandao);
  }
}
