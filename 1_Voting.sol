// SPDX-License-Identifier: UNDEFINED
pragma solidity ^0.8.0;
 
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
 
/// @title  Voting practice experiment
/// @author 0xLM
/// @notice This is a voting system practice code.
/// @custom:experimental This is an experimental contract, the stability of it is questionable. If you spot a bug feel free to contact!
 
contract Voting {
   
    address private owner;
 
    constructor() {
        owner = msg.sender;
    }
 
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not he owner!");
        _;
    }
 
    struct Answer {
        address answerAddress;
        bool voted;
        bool vote;
    }
   
    struct Question {
        string questionDescription;
        mapping (address => Answer) answers;
        uint deadline;
        uint numberOfVotes;
        uint numberOfTrues;
    }
 
    struct User {
        address userAddress;
        bool registered;
    }
 
    mapping (address => User) public userList;
    mapping (uint => Question) public questionList;
 
    uint currentQuestion;
    uint deadline = 1 hours;
 
    function userRegistration() public {
    require(userList[msg.sender].registered == false, "Address has already registered...");
    userList[msg.sender].registered = true;
    userList[msg.sender].userAddress = msg.sender;
    console.log("User registered with %s address", msg.sender);
    }
 
    function addQuestion(string memory _questionDescription) external onlyOwner {
        currentQuestion++;
        questionList[currentQuestion].questionDescription = _questionDescription;
        questionList[currentQuestion].deadline = block.timestamp + deadline;
        console.log("'%s' saved and can be answered till %s", questionList[currentQuestion].questionDescription, block.timestamp + deadline);
    }
 
    function vote(bool _vote) public {
        require(userList[msg.sender].registered == true, "You need to register first...");
        require(questionList[currentQuestion].answers[msg.sender].voted == false, "You have already voted for the current question...");
        require(block.timestamp <= questionList[currentQuestion].deadline, "Voting deadline has passed...");
        questionList[currentQuestion].answers[msg.sender].vote = _vote;
        questionList[currentQuestion].numberOfVotes++;
        if(questionList[currentQuestion].answers[msg.sender].vote == true){
            questionList[currentQuestion].numberOfTrues++;
        }
        questionList[currentQuestion].answers[msg.sender].voted = true;
        console.log("For the following question: %s, you voted %s", questionList[currentQuestion].questionDescription, questionList[currentQuestion].answers[msg.sender].vote);
    }
 
    function getNumberOfVotes() public view returns(string memory) {
        console.log("The last question was: %s \n Total votes: %s \n TRUE votes: %s", questionList[currentQuestion].questionDescription, questionList[currentQuestion].numberOfVotes, questionList[currentQuestion].numberOfTrues);
        return string(abi.encodePacked("Question:", questionList[currentQuestion].questionDescription, "| NUMBER OF VOTES: ", questionList[currentQuestion].numberOfVotes, "|NUMBER OF TRUE ANSWERS: ", questionList[currentQuestion].numberOfTrues));
    }
 
}
 
 

