// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FundMe {

    // We add the 1e18 because getConversionRate will return a number 1e18 times bigger than
    // the actual number, so we have to adapt the constant below too.
    uint256 public minimumUsd = 5*1e18; 

    function fund() public payable{
        require(getConversionRate(msg.value) >= minimumUsd, "Not enough ETH in the transaction");
    }

    function withdraw() public {

    }

    function getPrice() public view returns(uint256) {
        AggregatorV3Interface dataFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
        // We base on docs (test.sol script) to know what we get from latestRoundData
        (, int256 price ,,,) = dataFeed.latestRoundData();
        // 1 ETH are 1e18 wei
        // Results in solidity has no decimal, but last 8 numbers are the decimals.
        // price will be the price in $ of 1 ETH
        // So ($/ETH) with "18 decimal places" would be
        return uint256 (price * 1e10);
    }

    function getConversionRate(uint ethAmount) public view returns(uint256){
        // About 4000_000000000000000000 (18 decimals)
        uint256 ethPrice = getPrice();
        // ethAmount will be given in wei, so it will be divided between 1e18 (1 ETH are 1e18 wei)
        // So (USD/ETH)*wei*(ETH/wei) = USD
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;

        return ethAmountInUsd;
    }

    function getVersion() public view returns(uint256) {
        return AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).version();
    }
}