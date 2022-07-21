// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";
import "./calcStuff.sol";
 
/// @title Lottery Simulator experiment
/// @author 0xLM
/// @notice This application is meant to simulate a lottery, where users can buy one ticket and guess 5 different numbers. When the buying phase is closed the winning numbers are selected and the prizes transferred to the winners.
/// @custom:experimental This is an experimental contract, the stability of it is questionable. If you spot a bug feel free to contact!
 
contract Lottery is Ownable,calcStuff {
 
uint gameNum = 1;
uint gameTime = 1 minutes;
uint ticketPrice = 2 ether;
uint lotteryNonce;
enum GameStatus{idle, buyStarted, buyClosed, combinationsSet, scoresChecked, fundsTransferred}
 
struct Bet {
    uint[5] myBet;
    address myAddress;
    bool userMadeBet;
    uint hits;
    bool priceTransferred;
}
 
struct Game {
    uint id;
    uint totalPrice;
    mapping(uint => uint) priceFor;
    GameStatus gameStatus;
    mapping(uint => Bet) betId;
    uint[5] winningNumbers;
    uint deadline;
    uint numberOfBets;
}
 
mapping(uint => Game) public games;
 
// 1. STARTING GAME
function startGame() public onlyOwner{
    require(games[gameNum].gameStatus == GameStatus.idle, "Round hasnt started...");
    games[gameNum].id = gameNum;
    games[gameNum].gameStatus = GameStatus.buyStarted;
    games[gameNum].deadline = block.timestamp + gameTime;
 
    console.log("The no. %s game has just started, you have %s minutes to buy your ticket!", gameNum, gameTime/60);
}
 
// 2. BUYING TICKET FOR A PRESET PRICE
function bet(uint A, uint B, uint C, uint D, uint E) external payable {
    require(games[gameNum].gameStatus == GameStatus.buyStarted, "No active game to join...");
    require(noDuplicates(A, B, C, D, E) == true, "Different numbers only!!");
    require(msg.value == ticketPrice, "Insufficient funds...");
    games[gameNum].betId[games[gameNum].numberOfBets].myBet = [A, B, C, D, E];
    games[gameNum].betId[games[gameNum].numberOfBets].myAddress = msg.sender;
    games[gameNum].betId[games[gameNum].numberOfBets].userMadeBet = true;
    games[gameNum].numberOfBets++;
    games[gameNum].totalPrice += (msg.value / 2);
    string memory toPrint = string.concat(Strings.toString(A)," ",Strings.toString(B)," ",Strings.toString(C)," ",Strings.toString(D)," ",Strings.toString(E));
 
    console.log("Your numbers are: %s", toPrint);
}
 
// 3. ENDING GAME
function endGame() public onlyOwner{
    require(games[gameNum].gameStatus == GameStatus.buyStarted, "Either there is no ongoing games or the deadline has not passed...");
    require(games[gameNum].deadline <= block.timestamp, "Game is still on...");
    games[gameNum].gameStatus = GameStatus.buyClosed;
 
    console.log("The no. %s game has just finished with %s tickets sold...", gameNum, games[gameNum].numberOfBets);
}
 
// 4/A. SETTING RANDOM WINNING COMBINATION
function setWinningCombinations() public onlyOwner {
    require(games[gameNum].gameStatus == GameStatus.buyClosed, "Wait for the game to finish...");
    uint actualNumber;
    string memory toPrint;
    for(uint i = 0; i < 5; i++) {
        while (checkIfInArray(actualNumber, games[gameNum].winningNumbers) == true) {
            actualNumber = uint(keccak256(abi.encodePacked(msg.sender, lotteryNonce, block.timestamp))) %  91;
            lotteryNonce++;
        }
        games[gameNum].winningNumbers[i] = actualNumber;
        toPrint = string.concat(toPrint," ",(Strings.toString(actualNumber)));
    }
    games[gameNum].gameStatus = GameStatus.combinationsSet;
   
    console.log("The winning numbers are: %s", toPrint);
}
 
// 4/B FOR TESTING PURPOSE (call instead of 'setWinningCombinations()')
function testWin() public onlyOwner {
    require(games[gameNum].gameStatus == GameStatus.buyClosed, "Wait for the game to finish...");
    games[gameNum].winningNumbers = [1,2,3,4,5];
    games[gameNum].gameStatus = GameStatus.combinationsSet;
    console.log("The winning numbers are: [1, 2, 3, 4, 5]");
    }
 
// 5. CHECKING SCORES AND CALCULATES PRIZES
function checkScores() public onlyOwner {
    require(games[gameNum].gameStatus == GameStatus.combinationsSet, "Set winning combination first...");
    uint _hitcount;
    uint numberOfFive;
    uint numberOfFour;
    uint numberOfThree;
 
    for(uint i = 0; i < games[gameNum].numberOfBets; i++) {
        _hitcount = hitCount(games[gameNum].betId[i].myBet, games[gameNum].winningNumbers);
        if(_hitcount == 5) numberOfFive++;
        else if(_hitcount == 4) numberOfFour++;
            else if(_hitcount == 3) numberOfThree++;
        games[gameNum].betId[i].hits = _hitcount;
        console.log("%s. bet checked, number of hits: %s", i+1, _hitcount);
    }
    games[gameNum].gameStatus = GameStatus.scoresChecked;
    if(numberOfThree != 0) games[gameNum].priceFor[3] = games[gameNum].totalPrice * 10 / 100 / numberOfThree;
    if(numberOfFour != 0) games[gameNum].priceFor[4] = games[gameNum].totalPrice * 30 / 100 / numberOfFour;
    if(numberOfFive != 0) games[gameNum].priceFor[5] = games[gameNum].totalPrice * 60 / 100 / numberOfFive;
 
    console.log("Total number of 5/5 : %s, category price: %s", numberOfFive, games[gameNum].priceFor[5]);
    console.log("Total number of 4/5 : %s, category price: %s", numberOfFour, games[gameNum].priceFor[4]);
    console.log("Total number of 3/5 : %s, category price: %s", numberOfThree, games[gameNum].priceFor[3]);
    }
 
// 6. TRANSFERRING THE PREVIUSLY CALCULATED PRIZES
function transferPrices() public payable onlyOwner {
    require(games[gameNum].gameStatus == GameStatus.scoresChecked, "Check scores first!");
    uint _myPrice;
    for(uint i = 0; i < games[gameNum].numberOfBets; i++) {
        if (games[gameNum].betId[i].hits > 2) {
            if(games[gameNum].betId[i].hits == 5) _myPrice = games[gameNum].priceFor[5];
            if(games[gameNum].betId[i].hits == 4) _myPrice = games[gameNum].priceFor[4];
            if(games[gameNum].betId[i].hits == 3) _myPrice = games[gameNum].priceFor[3];
            _myPrice = games[gameNum].priceFor[games[gameNum].betId[i].hits];
            payable(games[gameNum].betId[i].myAddress).transfer(_myPrice);
            console.log("%s transferred to %s", _myPrice, games[gameNum].betId[i].myAddress);
        }
    }
    games[gameNum].gameStatus = GameStatus.fundsTransferred;
    gameNum++;
    console.log("Price transfers complete!");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
 
contract calcStuff {
 
function noDuplicates(uint A, uint B, uint C, uint D, uint E) internal pure returns(bool) {
        if(A == B || A == C || A == D || A == E || B == C || B == D || B == E || C == D || C == E || D == E) return false;
        else return true;
    }  
 
function checkIfInArray(uint _number, uint[5] memory _array) internal pure returns(bool) {
    for(uint i = 0; i < _array.length; i++) {
        if (_array[i] == _number) return true;
    }
    return false;
    }
 
function hitCount(uint[5] memory _bet, uint[5] memory _winning) internal pure returns(uint) {
    uint count;
    for (uint i = 0; i < 5 ;i++) {
        if (checkIfInArray(_bet[i], _winning)) count++;
    }
    return count;
    }
}
