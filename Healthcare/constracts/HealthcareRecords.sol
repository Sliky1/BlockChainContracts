// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract HealthcareRecords {
    address owner;

    struct Record {
        //记录
        uint256 recordID; //ID
        string patientName; //name
        string diagnosis; //病状
        string treatment; //治疗方案
        uint256 timestamp; //时间戳
    }

    mapping(uint256 => Record[]) private patientRecords;

    mapping(address => bool) private authorizedProviders;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this function");
        _;
    }

    modifier onlyAuthorizedProviders() {
        require(authorizedProviders[msg.sender], "Not an authorized providers");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function authorizedProvider(address provider) public onlyOwner{
        authorizedProviders[provider] = true;
    }

    function addRecord(uint256 patientID,string memory patientName,string memory diagnosis ,string memory treatment) public onlyAuthorizedProviders{
        uint256 recordID = patientRecords[patientID].length +1;
        patientRecords[patientID].push(Record(recordID,patientName,diagnosis,treatment,block.timestamp));
    }

    function getPatientRecords(uint256 patientID) public view onlyAuthorizedProviders returns(Record[] memory){
        return patientRecords[patientID];
        
    }






}
