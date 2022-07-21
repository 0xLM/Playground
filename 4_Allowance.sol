//SPDX-License-Identifier: MIT
 
pragma solidity 0.8.1;
 
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
 
/// @title Budget allowance experiment
/// @author 0xLM
/// @notice This program is meant to represent a pocket money dispenser. The owner can set either instant or time dependent allowances, which then can be claimed by the designated user.
/// @custom:experimental This is an experimental contract, the stability of it is questionable. If you spot a bug feel free to contact!
 
contract MonthlyAllowance is Ownable {
 
uint private restingPeriod = 10 seconds;
 
struct timedDeposit {
    uint _depositAmount;
    uint _claimableAfter;
    bool _claimed;
}
 
struct User {
    uint instantAllowance;
    uint sumWithdraw;
    bool paused;
    uint depositNum;
    timedDeposit[] deposits;
}
 
event allowanceChanged(address _address, uint _amount);
event timedAllowanceAdded(address _address, uint _amount, uint _deadline);
event userWithdrawn(address _address, uint _amount);
 
mapping(address => User) users;
 
function setInstantAllowance(address _user, uint _amount) public onlyOwner{
    users[_user].instantAllowance += _amount;
 
    emit allowanceChanged(_user, users[_user].instantAllowance);
    console.log("%s amount allowance set to user: %s", _amount, _user);
}
 
function setTimedAllowance(address _user, uint _amount) public onlyOwner{
    timedDeposit memory deposit = timedDeposit(_amount, block.timestamp + restingPeriod, false);
    users[_user].deposits.push(deposit);
 
    emit timedAllowanceAdded(msg.sender, _amount, users[_user].deposits[users[_user].depositNum]._claimableAfter);
    console.log("%s amount timed allowance set to user: %s, that can be claimed after %s", _amount, _user, users[_user].deposits[users[_user].depositNum]._claimableAfter);
    users[_user].depositNum++;
}
 
function userWithdraw(uint _amount) public payable {
    require(users[msg.sender].paused != true, "User paused...");
    require(withdrawableAmount(msg.sender) >= _amount, "Insufficient allowance...");
    require(address(this).balance >= _amount, "Not enough ether on contract...");
    users[msg.sender].instantAllowance -= _amount;
    users[msg.sender].sumWithdraw += _amount;
    payable(msg.sender).transfer(_amount);
 
    emit userWithdrawn(msg.sender, _amount);
    console.log("%s amount has been withdrawn to user address: %s, currently withdrawable on account:%s", _amount, msg.sender, users[msg.sender].instantAllowance);
}
 
function withdrawableAmount(address _user) private returns(uint){
    for(uint i = 0; i < users[_user].deposits.length; i++){
        if(users[_user].deposits[i]._claimed == false && users[_user].deposits[i]._claimableAfter < block.timestamp){
            users[_user].instantAllowance += users[_user].deposits[i]._depositAmount;
            users[_user].deposits[i]._claimed = true;
            console.log("Allowance claimed, amount: %s, deadline: %s", users[_user].deposits[i]._depositAmount, users[_user].deposits[i]._claimableAfter);
        }
    }
    return users[_user].instantAllowance;
}
 
function pendingAmount(address _user) private view {
    for(uint i = 0; i < users[_user].deposits.length; i++){
        if(users[_user].deposits[i]._claimed == false){
            console.log("%s due after %s", users[_user].deposits[i]._depositAmount, users[_user].deposits[i]._claimableAfter);
        }
    }
}
 
function pauseUser(address _user) public onlyOwner {
    users[_user].paused = !users[_user].paused;
 
    if(users[_user].paused == true) console.log("User paused");
    else console.log("User UNpaused");
}
 
function checkAllowance() public {
    withdrawableAmount(msg.sender);
    pendingAmount(msg.sender);
    console.log("Total allowance: %s", users[msg.sender].instantAllowance);
}
 
function contractBalance() public view returns(uint) {
    return address(this).balance;
}
 
receive() external payable {
    console.log("%s received from %s...", msg.value, msg.sender);
}
 
}
 
