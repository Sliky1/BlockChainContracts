// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract voting {
    //一个mapping来存储候选人的得票数
    mapping(string => uint256) votes;
    string[] private List;
    //一个vote函数，允许用户投票给某个候选人
    function vote(string memory name) public {
        if (votes[name] == 0) {
            List.push(name);
        }
        votes[name]++;
    }
    //一个getVotes函数，返回某个候选人的得票数
    function getVotes(string memory name) public view returns (uint256) {
        return votes[name];
    }
    //一个resetVotes函数，重置所有候选人的得票数
    function resetVotes() public {
        for (uint i = 0; i < List.length; i++) {
            votes[List[i]] = 0;
        }
        delete List;
    }
}
