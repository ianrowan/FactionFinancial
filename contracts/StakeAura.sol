// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract AuraStaking is PaymentSplitter{

    IERC20 public stakingToken;
    
    address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

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
                              shares/10
      wallets[0] = rewardpool ex 4
      wallets[1] = tresury ex 4
      remainder share = liq pool 2
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

      //Release to shares of reward pool + tresury
      releaseAll(stakingToken);
      //Add remaining tokens to LP
      _addLiquidity();
    }

    function withdraw(uint _amount) external updateReward(msg.sender) isBond(_amount){
      require(_balances[msg.sender] >= _amount);

      _totalSupply -= _amount;
      _balances[msg.sender] -= _amount;
      _nodeCount[msg.sender] -= _amount/10;
      bondCount -= _amount/10;

      stakingToken.transferFrom(payee(0), msg.sender, _amount * shares(payee(0)));
      stakingToken.transferFrom(payee(2), msg.sender, _amount * shares(payee(2)));
    }

    function getReward() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        stakingToken.transferFrom(payee(0), msg.sender, reward);
    }

    function _addLiquidity() internal {
      
      uint balance = stakingToken.balanceOf(address(this));
      IUniswapV2Router02 UniswapV2Router02 = IUniswapV2Router02(ROUTER);

      address[] memory path = new address[](2);
      path[0] = address(stakingToken);
      path[1] = UniswapV2Router02.WETH();

      stakingToken.approve(ROUTER, balance);

      uint preBal = IERC20(path[1]).balanceOf(address(this));

      UniswapV2Router02.swapExactTokensForETHSupportingFeeOnTransferTokens(
        balance/2,
        0,
        path,
        address(this),
        block.timestamp
        );

      uint postBal = IERC20(path[1]).balanceOf(address(this));

      IERC20(path[1]).approve(ROUTER, postBal);
      UniswapV2Router02.addLiquidity(
        path[0],
        path[1],
        balance/2,
        postBal - preBal,
        0,
        0,
        address(this),
        block.timestamp
        );
    }

    function removeLiquidity(uint shares) public isOwner {
      IUniswapV2Router02 UniswapV2Router02 = IUniswapV2Router02(ROUTER);
      address pair = IUniswapV2Factory(FACTORY).getPair(address(stakingToken), UniswapV2Router02.WETH());

      uint liquidity = IERC20(pair).balanceOf(address(this));
      IERC20(pair).approve(ROUTER, liquidity);

      require(liquidity > shares, "Not enough liquidity shares");

      (uint amountA, uint amountB) = UniswapV2Router02.removeLiquidity(
        address(stakingToken),
        UniswapV2Router02.WETH(),
        shares,
        0, 0,
        address(this),
        block.timestamp
        );

        IERC20(UniswapV2Router02.WETH()).transfer(msg.sender, amountB);
        releaseAll(stakingToken);
    }

    function getLiquidityShares() public isOwner view returns(uint liquidity){

      IUniswapV2Router02 UniswapV2Router02 = IUniswapV2Router02(ROUTER);
      address pair = IUniswapV2Factory(FACTORY).getPair(address(stakingToken), UniswapV2Router02.WETH());

      return IERC20(pair).balanceOf(address(this));
    }

    function balanceOf(address addr) external view returns(uint){
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
