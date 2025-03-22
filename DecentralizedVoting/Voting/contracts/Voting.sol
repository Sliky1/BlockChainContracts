// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    struct Candidate {
        string name;
        uint256 voteCount; //得票数
    }

    Candidate[] public candidates;
    address owner;
    mapping(address => bool) public voters;

    uint256 public votingStart; //投票开始的时间戳
    uint256 public votingEnd; //投票结束的时间戳

    constructor(string[] memory _candidateNames, uint256 _durationInMinutes) {
        for (uint256 i = 0; i < _candidateNames.length; i++) {
            candidates.push(
                Candidate({name: _candidateNames[i], voteCount: 0})
            );
            //构造函数遍历 _candidateNames 数组，为每个候选人创建一个 Candidate 结构体，并添加到 candidates 数组中
        }
        owner = msg.sender;
        votingStart = block.timestamp;
        votingEnd = block.timestamp + (_durationInMinutes * 1 minutes);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function addCandidate(string memory _name) public onlyOwner {
        candidates.push(Candidate({name: _name, voteCount: 0}));
    }

    function vote(uint256 _candidateIndex) public {
        require(!voters[msg.sender], "You have already voted."); //检查调用者是否已经投票。
        require(
            _candidateIndex < candidates.length,
            "Invalid candidate index."
        );
        //检查候选人索引是否有效。
        candidates[_candidateIndex].voteCount++;
        voters[msg.sender] = true;
    }

    function getAllVotesOfCandiates() public view returns (Candidate[] memory) {
        return candidates; //获取所有候选人的得票信息
    }

    function getVotingStatus() public view returns (bool) {
        return (block.timestamp >= votingStart && block.timestamp < votingEnd); //获取投票状态。
    }

    function getRemainingTime() public view returns (uint256) {
        require(block.timestamp >= votingStart, "Voting has not started yet."); //获取剩余投票时间。
        if (block.timestamp >= votingEnd) {
            return 0;
        }
        return votingEnd - block.timestamp;
    }
}
