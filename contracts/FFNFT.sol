// contracts/FoundersBond.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155FF.sol";

contract FounderBond is ERC1155FF {
    uint256 public constant GOLD = 0;
    uint256 public constant PLATINUM = 1;
    uint256 public constant DIAMOND = 2;
    
    //TODO: Before Mint set name correctly, adjust prices in ERC1155.sol, burn function
    constructor() ERC1155FF("https://ai-art.s3.amazonaws.com/Founders/{id}.json", "Faction Financial TEST") {
        _mint(msg.sender, GOLD, 100, "");
        _mint(msg.sender, PLATINUM, 100, "");
        _mint(msg.sender, DIAMOND, 100, "");
    }
}