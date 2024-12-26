// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { NFTs } from "../../codegen/tables/NFTs.sol";

contract NFTSystem is System {
  function setNfts(address[] memory nfts) public {
    NFTs.setNfts(_msgSender(), nfts);
  }

  function pushNfts(address nft) public {
    NFTs.pushNfts(_msgSender(), nft);
  }

  function popNfts() public {
    NFTs.popNfts(_msgSender());
  }

  function updateNfts(uint256 index, address nft) public {
    NFTs.updateNfts(_msgSender(), index, nft);
  }

  function deleteNfts() public {
    NFTs.deleteRecord(_msgSender());
  }
}
