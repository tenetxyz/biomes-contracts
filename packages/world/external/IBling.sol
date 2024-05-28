// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

interface IBling is IERC20, IERC20Permit {
  function getBiomeWorldAddress() external view returns (address);

  function mint(address to, uint256 amount) external;

  function burn(address account, uint256 value) external;
}
