//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
 
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
 
/// @title Blog practice
/// @author 0xLM
/// @notice Users can write, edit, and delete posts. (but only theirs)
/// @custom:experimental This is an experimental contract, the stability of it is questionable.If you spot a bug feel free to contact me!
 
contract Blog is Ownable {
   
    event postSaved(uint indexed _id, address indexed _address);
    event postEdited(uint indexed _id);
    event postDeleted(uint indexed _id);
   
    uint private entryCounter;
 
    struct Post {
        address writer;
        string title;
        string text;
        uint writeDate;
        uint lastUpdated;
    }
 
    modifier onlyWriter(uint _id) {
        require(blogEntries[_id].writer == msg.sender, "You are not the owner of the article...");
        _;
    }
 
    mapping(uint => Post) blogEntries;
 
    function writePost( string memory _title, string memory _text) public {
        blogEntries[entryCounter].writer = msg.sender;
        blogEntries[entryCounter].title =_title;
        blogEntries[entryCounter].text =_text;
        blogEntries[entryCounter].writeDate = block.timestamp;
        blogEntries[entryCounter].lastUpdated = block.timestamp;
        emit postSaved(entryCounter, msg.sender);
        entryCounter++;
 
    }
 
    function showMyPosts() public view {
        for (uint i = 0; i < entryCounter; i++) {
            if(blogEntries[i].writer == msg.sender) {
                console.log("Id: %s", i);
                console.log("Title: %s, Content: %s", blogEntries[i].title, blogEntries[i].text );
                console.log("Created: %s, Last Updated: %s", blogEntries[i].writeDate, blogEntries[i].lastUpdated );
            }
        }
    }
 
    function showAllPosts() public view {
        for (uint i = 0; i < entryCounter; i++) {
                console.log("Id: %s", i);
                console.log("Title: %s, Content: %s", blogEntries[i].title, blogEntries[i].text );
                console.log("Created: %s, Last Updated: %s", blogEntries[i].writeDate, blogEntries[i].lastUpdated );
        }
    }
 
    function editPost(uint _id, string memory _newtitle, string memory _newtext) public onlyWriter(_id) {
        blogEntries[_id].text = _newtitle;
        blogEntries[_id].text = _newtext;
        blogEntries[_id].lastUpdated = block.timestamp;
        emit postEdited(_id);
    }
 
    function deletePost(uint _id) public onlyWriter(_id) {
        delete(blogEntries[_id]);
        emit postDeleted(_id);
    }
}

 

