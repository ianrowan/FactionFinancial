// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/*
  The Purpose of the MultiWallet is to provide custody of a single users total holdings of a given stable coin.
   User should have the ability to:
   - deposit a given ERC20 token or ETH
   - withdraw a given ERC20 token or ETH 
   - get balance of any ERC20 and/or ETH
   - Provide external services a method to receive ERC20 on behalf
*/
contract MultiWallet {

  address private owner;
  mapping(address => uint) private _contractERC20balances;
  mapping(address => uint) private _userETHBalances;
  mapping(address => mapping(address => uint)) _userERC20Balances;
  mapping(address => address[]) _userERC20TokensOwned;

  constructor() {
    owner = msg.sender;
  }

  function depositEth() public payable {
    require(msg.value > 0, "must send some eth");
    _userETHBalances[msg.sender] += msg.value;
  }

  function depositToken(address tokenAddress, uint qty) public {
    require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), qty), "token transfer failed");
    
    if(_userERC20Balances[msg.sender][tokenAddress] == 0){
      _userERC20TokensOwned[msg.sender].push(tokenAddress);
    }

    _userERC20Balances[msg.sender][tokenAddress] += qty;
    _contractERC20balances[tokenAddress] += qty;
  }

  function withdrawToken(address tokenAddress, uint qty) public{
    require(_userERC20Balances[msg.sender][tokenAddress] >= qty);
    _userERC20Balances[msg.sender][tokenAddress] -= qty;
    _contractERC20balances[tokenAddress] -= qty;
    require(IERC20(tokenAddress).transfer(msg.sender, qty), "token transfer failed");
  }

  function getBalance(address tokenAddress) public view returns(uint balance){
    balance = tokenAddress == address(0) ? _userETHBalances[msg.sender] : _userERC20Balances[msg.sender][tokenAddress];
  }

  function receiveERC20(address tokenAddress, address fromAddress, uint qty) public {
    require(IERC20(tokenAddress).transferFrom(fromAddress, address(this), qty), "token transfer failed");
    _userERC20Balances[msg.sender][tokenAddress] += qty;
    _contractERC20balances[tokenAddress] += qty;
  }

  function depositMultTokens(address[] memory tokenAddrs, uint[] memory qtys) public {
    require(tokenAddrs.length == qtys.length, "Missing token or qty");
    for(uint i=0; i < tokenAddrs.length; i++){
      depositToken(tokenAddrs[i], qtys[i]);
    }
  }

  function withdrawMultTokens(address[] memory tokenAddrs, uint[] memory qtys) public {
    require(tokenAddrs.length == qtys.length, "Missing token or qty");
    for(uint i=0; i < tokenAddrs.length; i++){
      withdrawToken(tokenAddrs[i], qtys[i]);
    }
  }

  function withdrawAll() public {
    for(uint i = 0; i < _userERC20TokensOwned[msg.sender].length; i++){
      withdrawToken(_userERC20TokensOwned[msg.sender][i], _userERC20Balances[msg.sender][_userERC20TokensOwned[msg.sender][i]]);
    }
  }
}
