// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract AuraToken is ERC20, ERC20Burnable {
  using Address for address;

  address private owner;
  address[] private otherContracts;

  constructor(string memory symbol, string memory name) ERC20(name, symbol){
    owner = msg.sender;
    _mint(msg.sender, 10000000);
  }

  //Allows operators to get Users total balance + balance in remote contracts(staking, etc)
  function remoteBalanceOf(address user) public returns(uint){
    uint balance = balanceOf(user);
    for(uint i = 0; i < otherContracts.length; i++){
       bytes memory result = otherContracts[i].functionCall(
        abi.encodeWithSignature("balanceOf(address)", user)
      );
      balance += abi.decode(result, (uint));
    }
    return balance;
  }

  function addBalanceContract(address contr) public isOwner {
    require(contr.isContract());
    otherContracts.push(contr);
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
