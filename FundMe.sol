// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract FundMe {

    uint256 public minimumUsd = 5;

    function fund() public payable{
        require(msg.value >= minimumUsd, "Not enough ETH in the transaction");
    }

    function withdraw() public {

    }
}