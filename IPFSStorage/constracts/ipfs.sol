// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

contract ipfs{
    string private ipfshash;

    //setter
    function setIPFSHash(string memory _ipfshash) public {
        ipfshash = _ipfshash;
    }

    //getter

    function getIPFSHash () public view returns(string memory){
        return ipfshash;
    }
}