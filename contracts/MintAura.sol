// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MintAura {

  IERC20 private auraToken;

  address private owner;
  uint private pricePerToken;
  bool internal locked;
  mapping(address => uint) private mintMember;

  event Minted(address indexed addr, uint qtyMinted);
  event NewXrate(uint newRate);

  constructor(address _auraAddress, uint _pricePerToken) {
    owner = msg.sender;
    auraToken = IERC20(_auraAddress);
    pricePerToken = _pricePerToken;
  }

  modifier noReentrant() {
      require(!locked, "No re-entrancy");
      locked = true;
      _;
      locked = false;
  }

  modifier isOwner(){
    require(msg.sender == owner, "Access denied");
    _;
  }

  function mint(uint qty) public payable noReentrant{
    require(msg.value >= qty * pricePerToken * 1e17, "Insufficient Funds");
    require(auraToken.balanceOf(address(this)) >= qty, "Not enough mint funds left");

    auraToken.transfer(msg.sender, qty);
    mintMember[msg.sender] += qty;

    emit Minted(msg.sender, qty);
  }

  function withdraw() public isOwner{
    payable(owner).transfer(address(this).balance);
  }

  function withdrawTokens(uint qty) public isOwner{
    auraToken.transfer(owner, qty);
  }

  function adjustExchangeRate(uint newRate) public isOwner{
    pricePerToken = newRate;
    emit NewXrate(newRate);
  }

  function getMintTotal(address addr) public view returns(uint total){
    return mintMember[addr];
  }
}
