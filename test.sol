// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;  

contract SimlpeStorage {
    //This gets in initialized to zero!
    // <- This means that this section is a comment
    uint256 favoriteNumber; 
    
    mapping(string => uint256 ) public nameToFaoriteNumber;//dic

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    //unit256 public favoriteNumberList
    People[] public  people;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    //view，pure
    function retrieve() public view returns(uint256){ 
        return favoriteNumber;
    }

    //calldata,memory,storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFaoriteNumber[_name] = _favoriteNumber;
    } 
}