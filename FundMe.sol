// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";

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