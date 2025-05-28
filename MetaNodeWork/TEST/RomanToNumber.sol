// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RomanToNumber {

    function romanToInt(string memory s) public pure returns (uint) {
        // Check input non-empty
        require(bytes(s).length > 0, "Input string cannot be empty");

        // Define single character mappings using arrays
        bytes1[7] memory chars = [bytes1('I'), 'V', 'X', 'L', 'C', 'D', 'M'];
        uint[7] memory values = [uint(1), 5, 10, 50, 100, 500, 1000];

        // Convert string to bytes
        bytes memory b = bytes(s);

        // Validate characters and check for illegal repetitions
        uint[7] memory counts; // Track repetitions of I, V, X, L, C, D, M
        for (uint j = 0; j < b.length; j++) {
            bool valid = false;
            for (uint k = 0; k < 7; k++) {
                if (b[j] == chars[k]) {
                    counts[k]++;
                    valid = true;
                    break;
                }
            }
            require(valid, "Invalid character");
        }
        require(counts[0] <= 3, "Too many I characters");
        require(counts[1] <= 1, "Too many V characters");
        require(counts[2] <= 3, "Too many X characters");
        require(counts[3] <= 1, "Too many L characters");
        require(counts[4] <= 3, "Too many C characters");
        require(counts[5] <= 1, "Too many D characters");
        require(counts[6] <= 3, "Too many M characters");

        // Convert to integer using do-while
        uint result = 0;
        uint i = 0;
        do {
            // Get current value
            uint currentValue = 0;
            for (uint k = 0; k < 7; k++) {
                if (b[i] == chars[k]) {
                    currentValue = values[k];
                    break;
                }
            }

            // Get next value (0 if no next character)
            uint nextValue = 0;
            if (i + 1 < b.length) {
                for (uint k = 0; k < 7; k++) {
                    if (b[i + 1] == chars[k]) {
                        nextValue = values[k];
                        break;
                    }
                }
            }

            if (currentValue < nextValue) {
                result -= currentValue;
            } else {
                result += currentValue;
            }
            i++;
        } while (i < b.length);

        // Validate result range
        require(result <= 3999, "Result exceeds 3999");

        return result;
    }
}