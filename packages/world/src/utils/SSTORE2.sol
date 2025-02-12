// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Modified from Solady (https://github.com/vectorized/solmady/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from Saw-mon-and-Natalie (https://github.com/Saw-mon-and-Natalie)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                         CONSTANTS                          */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @dev We skip the first byte as it's a STOP opcode,
  /// which ensures the contract can't be called.
  uint256 internal constant DATA_OFFSET = 1;

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                        CUSTOM ERRORS                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @dev Unable to deploy the storage contract.
  error DeploymentFailed();

  /// @dev The storage contract address is invalid.
  error InvalidPointer();

  /// @dev Attempt to read outside of the storage contract's bytecode bounds.
  error ReadOutOfBounds();

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                         WRITE LOGIC                        */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @dev Writes `data` into the bytecode of a storage contract and returns its address.
  function write(bytes memory data) internal returns (address pointer) {
    /// @solidity memory-safe-assembly
    assembly {
      let originalDataLength := mload(data)

      // Add 1 to data size since we are prefixing it with a STOP opcode.
      let dataSize := add(originalDataLength, DATA_OFFSET)

      /**
       * ------------------------------------------------------------------------------+
       * Opcode      | Mnemonic        | Stack                   | Memory              |
       * ------------------------------------------------------------------------------|
       * 61 dataSize | PUSH2 dataSize  | dataSize                |                     |
       * 80          | DUP1            | dataSize dataSize       |                     |
       * 60 0xa      | PUSH1 0xa       | 0xa dataSize dataSize   |                     |
       * 3D          | RETURNDATASIZE  | 0 0xa dataSize dataSize |                     |
       * 39          | CODECOPY        | dataSize                | [0..dataSize): code |
       * 3D          | RETURNDATASIZE  | 0 dataSize              | [0..dataSize): code |
       * F3          | RETURN          |                         | [0..dataSize): code |
       * 00          | STOP            |                         |                     |
       * ------------------------------------------------------------------------------+
       * @dev Prefix the bytecode with a STOP opcode to ensure it cannot be called.
       * Also PUSH2 is used since max contract size cap is 24,576 bytes which is less than 2 ** 16.
       */
      mstore(
        // Do a out-of-gas revert if `dataSize` is more than 2 bytes.
        // The actual EVM limit may be smaller and may change over time.
        add(data, gt(dataSize, 0xffff)),
        // Left shift `dataSize` by 64 so that it lines up with the 0000 after PUSH2.
        or(0xfd61000080600a3d393df300, shl(0x40, dataSize))
      )

      // Deploy a new contract with the generated creation code.
      pointer := create(0, add(data, 0x15), add(dataSize, 0xa))

      // If `pointer` is zero, revert.
      if iszero(pointer) {
        // Store the function selector of `DeploymentFailed()`.
        mstore(0x00, 0x30116425)
        // Revert with (offset, size).
        revert(0x1c, 0x04)
      }

      // Restore original length of the variable size `data`.
      mstore(data, originalDataLength)
    }
  }

  /// @dev Reads a single byte from the deployed storage contract's data.
  /// @param pointer The address of the storage contract.
  /// @param index The zero-based index into the stored data (excluding the STOP opcode).
  /// @return result The byte at the given index.
  function readBytes1(address pointer, uint256 index) internal view returns (bytes1 result) {
    /// @solidity memory-safe-assembly
    assembly {
      let pointerCodesize := extcodesize(pointer)
      // If the code size is zero, the pointer is invalid.
      if iszero(pointerCodesize) {
        mstore(0x00, 0x11052bb4) // Function selector for InvalidPointer()
        revert(0x1c, 0x04)
      }
      // Ensure there is at least one data byte (code size must be greater than DATA_OFFSET).
      if iszero(gt(pointerCodesize, DATA_OFFSET)) {
        mstore(0x00, 0x84eb0dd1) // Function selector for ReadOutOfBounds()
        revert(0x1c, 0x04)
      }
      // Ensure the requested index is within bounds.
      if iszero(lt(index, sub(pointerCodesize, DATA_OFFSET))) {
        mstore(0x00, 0x84eb0dd1) // Function selector for ReadOutOfBounds()
        revert(0x1c, 0x04)
      }
      // Calculate the offset within the code.
      let offset := add(DATA_OFFSET, index)
      // Get a free memory pointer.
      let ptr := mload(0x40)
      // Copy one byte from the contract's code at the calculated offset.
      extcodecopy(pointer, ptr, offset, 1)
      // Load 32 bytes from memory and extract the first byte.
      result := byte(0, mload(ptr))
    }
  }
}
