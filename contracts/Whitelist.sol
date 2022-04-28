// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract Whitelist {

    IERC1155 public nft;

    address private owner;
    bool public whitelistEnabled = true;
    //address -> tier -> allowance
    mapping(address => mapping(uint => uint)) public whitelistAllowance;
    mapping(uint256 => uint256) public _prices;
    mapping(uint => uint) public _regPrices;

    event NFTSale(address addr, uint id, uint qty);

    constructor(address _nft) {
        owner = msg.sender;
        nft = IERC1155(_nft);
        _prices[0] = 20;
        _prices[1] = 40;
        _prices[2] = 60;
        _regPrices[0] = 25;
        _regPrices[1] = 50;
        _regPrices[2] = 75;
    }

    modifier isOwner(){
        require(msg.sender == owner);
        _;
    }

    function whitelistMint(uint id, uint qty) public payable{
        require(msg.value / 1e18 == _prices[id] * qty, "Insufficient Funds");
        require(whitelistAllowance[msg.sender][id] > 0, "Not a Whitelisted user");
        require(whitelistAllowance[msg.sender][id] >= qty, "Minted more than allowed, have you already minted more than 3?");
        require(whitelistEnabled, "Whitelist Not enabled");

        whitelistAllowance[msg.sender][id] -= qty;
        nft.safeTransferFrom(owner, msg.sender, id, qty, "");
        payable(owner).transfer(address(this).balance);

        emit NFTSale(msg.sender, id, qty);
    }

    function mint(uint id, uint qty) public payable{
        require(msg.value / 1e18 == _regPrices[id] * qty, "Insufficient Funds");

        nft.safeTransferFrom(owner,
        msg.sender,
        id,
        qty,
        "");
        payable(owner).transfer(address(this).balance);
        emit NFTSale(msg.sender, id, qty);    
    }

    function addAddress(address addr) public isOwner{
        whitelistAllowance[addr][0] = 3;
        whitelistAllowance[addr][1] = 3;
        whitelistAllowance[addr][2] = 3;
    }
    
    function addBatchAddress(address[] calldata addrs) public isOwner{
        for(uint i = 0; i < addrs.length; i++){
            addAddress(addrs[i]);
        }
    }

    function updateWhitelistPrice(uint tier1, uint tier2, uint tier3, bool stillOn) public isOwner{
        _prices[0] = tier1;
        _prices[1] = tier2;
        _prices[2] = tier3;
        whitelistEnabled = stillOn;
    }

    function updatePrice(uint tier1, uint tier2, uint tier3, bool stillOn) public isOwner{
        _regPrices[0] = tier1;
        _regPrices[1] = tier2;
        _regPrices[2] = tier3;
        whitelistEnabled = stillOn;
    }
}