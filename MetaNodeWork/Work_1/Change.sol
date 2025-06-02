//反转一个字符串。输入 "abcde"，输出 "edcba"

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StringReverser {
    function reverseString(string memory input) public pure returns (string memory) {

        bytes memory inputBytes = bytes(input);
        uint length = inputBytes.length;
        bytes memory reversedBytes = new bytes(length);

        for (uint i = 0; i < length; i++) {
            reversedBytes[i] = inputBytes[length - 1 - i];
        }

        return string(reversedBytes);
    }
}

