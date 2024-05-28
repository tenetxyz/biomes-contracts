// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract Bling is ERC20, ERC20Permit {
  address private biomeWorldAddress;

  error InvalidBiomeWorld(address biomeWorldAddress);

  constructor(address _biomeWorldAddress) ERC20("Bling", "BLNG") ERC20Permit("Bling") {
    biomeWorldAddress = _biomeWorldAddress;
  }

  modifier onlyBiomeWorld() {
    if (msg.sender != biomeWorldAddress) {
      revert InvalidBiomeWorld(biomeWorldAddress);
    }
    _; // Continue execution
  }

  function getBiomeWorldAddress() public view returns (address) {
    return biomeWorldAddress;
  }

  function mint(address to, uint256 amount) public onlyBiomeWorld {
    _mint(to, amount);
  }

  function burn(address account, uint256 value) public onlyBiomeWorld {
    _burn(account, value);
  }
}
