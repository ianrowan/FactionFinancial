// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract StakeERC1155 is ERC1155Holder{
  
  struct idVar{
    uint rewardRate;
    uint tokenValue;
    uint Expiration;
  }

  IERC1155 nft;
  IERC20 token;

  address private owner;
  uint idCount;
  uint public launchTime;
  uint private _tokenRate;

  mapping(uint => idVar) private idVars;
  mapping(address => mapping(uint => uint)) private _balances;
  mapping(address => uint) private _rewards;
  mapping(address => uint) private _lastUpdateTime;
  mapping(uint => bool) private _expired;

  constructor(
    address _nft,
    address _token,
    uint[] memory _rateWeights,
    uint[] memory _idValues,
    uint[] memory _idExpiration) {
    
    owner = msg.sender;
    nft = IERC1155(_nft);
    token = IERC20(_token);
    launchTime = block.timestamp;

    idCount = _rateWeights.length;

    for(uint i = 0; i < _rateWeights.length; i++){
      idVars[i] = idVar({rewardRate: _rateWeights[i], tokenValue: _idValues[i], Expiration: _idExpiration[i]});
    }
  }

  function stakeSingle(uint id, uint qty) public updateReward(msg.sender){
    nft.safeTransferFrom(msg.sender, address(this), id, qty, "");

    _balances[msg.sender][id] += 1;
    _lastUpdateTime[msg.sender] = block.timestamp;
  }

  function withdrawSingle(uint id, uint qty) public updateReward(msg.sender){
    require(_balances[msg.sender][id] >= qty);

    _balances[msg.sender][id] -= qty;

    token.transferFrom(owner, msg.sender, idVars[id].tokenValue * qty);
  }

  function getReward() public updateReward(msg.sender) {
    uint reward = _rewards[msg.sender];
    _rewards[msg.sender] = 0;

    token.transferFrom(owner, msg.sender, reward);
  }

  modifier updateReward(address account) {
    uint timeElapsed = (block.timestamp - _lastUpdateTime[account])/86400;
    for(uint i = 0; i < idCount; i++){
      uint qty = _balances[account][i];
      idVar memory vars = idVars[i];
      if(!_expired[i] && block.timestamp - launchTime < vars.Expiration){
        uint rate = vars.rewardRate;
        _rewards[account] += timeElapsed * rate * qty;
      }
      else{
        _expired[i] = true;
        uint value = vars.tokenValue;
        _rewards[account] += timeElapsed * _tokenRate * (value * qty/10);
      }
    }
    _;
  }

  function updateTokenReward(uint newRate) public isOwner {
    _tokenRate = newRate;
  }

  modifier isOwner(){
      require(msg.sender == owner, "Access denied");
      _;
    }
}
