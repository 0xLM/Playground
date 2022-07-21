// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
 
/// @title Silent auction experiment
/// @author 0xLM
/// @notice This application is meant to simulate a silent auction where the owner can register items, that can be won by bidding.
/// @custom:experimental This is an experimental contract, the stability of it is questionable. If you spot a bug feel free to contact!
 
contract SilentAuction is Ownable {
 
    uint itemCounter;
    uint baseDeadline = 1 minutes;
 
    struct Item {
        string name;
        uint highestPrice;
        uint successLimit;
        bool bidSuccessful;
        bool bidCompleted;
        address highestPriceAddress;
        uint deadline;
    }
 
    mapping(uint => Item) private items;
 
    function setItem(string memory _name, uint _startingPrice, uint _successLimit) public onlyOwner {
        items[itemCounter].name = _name;
        items[itemCounter].highestPrice = _startingPrice;
        items[itemCounter].successLimit = _successLimit;
        items[itemCounter].deadline = block.timestamp + baseDeadline;
 
        console.log("New item saved for bid!");
    }
 
    function currentItem() public view returns(string memory) {
        return items[itemCounter].name;
    }
 
    function  bid(uint _bid) public {
        require(items[itemCounter].deadline > block.timestamp, "Auction ended...");
        if (_bid > items[itemCounter].highestPrice) {
            items[itemCounter].highestPrice = _bid;
            items[itemCounter].highestPriceAddress = msg.sender;
        }
        console.log("Bid placed. Article: %s, value: %s", items[itemCounter].name, _bid);
    }
 
    function endCurrentBid() public payable onlyOwner {
        require(items[itemCounter].deadline <= block.timestamp, "Auction is still runnning...");
        if (items[itemCounter].highestPrice >= items[itemCounter].successLimit) {
            items[itemCounter].bidSuccessful = true;
            console.log("Bid won by: %s, for %s", items[itemCounter].highestPriceAddress, items[itemCounter].highestPrice);
        } else console.log("Bid unsuccessfull. The highest price did not meet the limit...");
        items[itemCounter].bidCompleted = true;
    }
}
 

