// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract AuraToken is ERC20, ERC20Burnable {

  address private owner;

  constructor(string memory symbol, string memory name) ERC20(name, symbol){
    owner = msg.sender;
    _mint(msg.sender, 10000000);
  }

  function mint(uint total) public isOwner{
    _mint(msg.sender, total);
  }

  function transferOwnership(address newOwner) public isOwner{
    owner = newOwner;
  }

  modifier isOwner(){
    require(msg.sender == owner, "Access denied");
    _;
  }
}
