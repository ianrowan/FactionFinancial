// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract AuraStaking is PaymentSplitter{

    IERC20 public stakingToken;

    address private owner;
    uint public rewardRate;
    uint private _totalSupply;
    uint public maxBonds = 40000;
    uint private bondCount;

    mapping(address => uint) public rewards;
    mapping(address => uint) private _balances;
    mapping(address => uint) private _nodeCount;
    mapping(address => uint) private _lastUpdateTime;

    /*
      wallets[0] = rewardpool
      wallets[1] = LPool
      wallets[2] = treasury
    */
    constructor(address _stakingToken, uint _rewardRate, address[] memory wallets, uint256[] memory walletShares)
    PaymentSplitter(wallets, walletShares) {
        stakingToken = IERC20(_stakingToken);
        rewardRate = _rewardRate/100;
        owner = msg.sender;
    }

    function earned(address account) public view returns (uint) {
        return
            (_nodeCount[account] *
                ((block.timestamp - _lastUpdateTime[account])/86400) * rewardRate) +
            rewards[account];
    }

    modifier updateReward(address account){
      rewards[account] = earned(account);
      _lastUpdateTime[account] = block.timestamp;
      _;
    }

    function stake(uint _amount) external updateReward(msg.sender) isBond(_amount) {
      require(maxBonds >= bondCount + _amount/10);

      stakingToken.transferFrom(msg.sender, address(this), _amount);

      _totalSupply += _amount;
      _balances[msg.sender] += _amount;
      _nodeCount[msg.sender] += _amount/10;
      bondCount += _amount/10;

      releaseAll(stakingToken);
    }

    function withdraw(uint _amount) external updateReward(msg.sender) isBond(_amount){
      require(_balances[msg.sender] >= _amount);

      _totalSupply -= _amount;
      _balances[msg.sender] -= _amount;
      _nodeCount[msg.sender] -= _amount/10;
      bondCount -= _amount/10;

      stakingToken.transferFrom(payee(0), msg.sender, _amount * shares(payee(0))/9);
      stakingToken.transferFrom(payee(2), msg.sender, _amount * shares(payee(2))/9);
    }

    function getReward() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        stakingToken.transferFrom(payee(0), msg.sender, reward);
    }

    function getStake(address addr) external view returns(uint){
      return _balances[addr];
    }
    
    function adjustMaxBonds(uint newMax) public isOwner {
      maxBonds = newMax;
    }

    function updateRewardRate(uint newRate) public isOwner {
      rewardRate = newRate/100;
    }

    function adjustUserTimestamp(address addr, uint numDays) public isOwner(){
      _lastUpdateTime[addr] -= numDays * 86400;
    }

    modifier isBond(uint _amount){
      require(_amount % 10 == 0, "Must purchase in 10 denominations");
      _;
    }

    modifier isOwner(){
      require(msg.sender == owner, "Access denied");
      _;
    }
}
