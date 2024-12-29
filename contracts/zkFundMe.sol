// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter{
    function getPrice() public view returns(uint256) {
        AggregatorV3Interface dataFeed = AggregatorV3Interface(
            0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF
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
        return AggregatorV3Interface(0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF).version();
    }
}

error NotOwner();

contract FundMe {

    using PriceConverter for uint256;

    // We add the 1e18 because getConversionRate will return a number 1e18 times bigger than
    // the actual number, so we have to adapt the constant below too.
    uint256 public constant MINIMUM_USD = 5*1e18; 

    address[] public funders;
    mapping(address funder => uint256 amountFunded) public addressToAmountFunded;

    address public immutable i_owner;

    constructor() {
        // I guess owner gets its value when contract is deployed, so later
        // in withdraw function owner == msg.sender condition could not be true
        // depending on the sender that ran the function.
        i_owner = msg.sender;
    }

    function fund() public payable{
        require(msg.value.getConversionRate() >= MINIMUM_USD, "Not enough ETH in the transaction");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for(uint256 funderIndex=0; funderIndex<funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        // 3 ways to send tokens to an account 
        // The first one is transfer. It returns nothing, so if it fails, operation is reverted.
        // The functions must receive a type payable address, which is obtained applying
        //  payable to the address, like below.
        // "this" is the the current contract, so address(this) is the address of this contract,
        // where we have previously added tokens through fund() function. "balance" is the amount
        // of token in the contract right now. 
        // payable(msg.sender).transfer(address(this).balance);
        // The second function is send, this one returns a boolean that shows if the operation
        // succeeded or failed. Therefore, if we want the operation to be reverted if the 
        // operation fails, we have to add a require() below.
        // bool operationSucceeded = payable(msg.sender).send(address(this).balance);
        // require(operationSucceeded, "Operation failed");
        // Finally, the third function is call. It returns two values, a boolean like send() and
        // an array of data in bytes. In this case we are not interested in such array, so we can
        // ignore it
        (bool operationSucceeded, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(operationSucceeded, "Operation failed"); 

    }

    modifier onlyOwner(){
        // require(msg.sender == i_owner, "Sender is not the owner!");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        // The line below corresponds to the rest of the code of the function, so the line above
        // is ran before when onlyOwner is passed as decorator to the function
        _;
    }

    // Users could send ETH directly to this contract without using fund() function. To avoid
    // this, we are gonna create a couple of default functions (solidity keywords):

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

}