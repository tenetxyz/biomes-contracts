// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

// Note: these functions are here because Solidity 0.8 cannot resolve selectors for overloaded functions
// See: https://github.com/ethereum/solidity/issues/3556
bytes4 constant BUILD_SELECTOR = bytes4(keccak256("build(uint8,(int16,int16,int16))"));
bytes4 constant BUILD_WITH_EXTRA_DATA_SELECTOR = bytes4(keccak256("build(uint8,(int16,int16,int16),bytes)"));

bytes4 constant MINE_SELECTOR = bytes4(keccak256("mine((int16,int16,int16))"));
bytes4 constant MINE_WITH_EXTRA_DATA_SELECTOR = bytes4(keccak256("mine((int16,int16,int16),bytes)"));

bytes4 constant TRANSFER_SELECTOR = bytes4(keccak256("transfer(bytes32,bytes32,uint8,uint16)"));
bytes4 constant TRANSFER_WITH_EXTRA_DATA_SELECTOR = bytes4(keccak256("transfer(bytes32,bytes32,uint8,uint16,bytes)"));

bytes4 constant TRANSFER_TOOL_SELECTOR = bytes4(keccak256("transferTool(bytes32,bytes32,bytes32)"));
bytes4 constant TRANSFER_TOOL_WITH_EXTRA_DATA_SELECTOR = bytes4(
  keccak256("transferTool(bytes32,bytes32,bytes32,bytes)")
);
