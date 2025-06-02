// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NumerToRoman {

    function intToRoman(uint num) public pure returns (string memory) {
        // Check input range
        require(num >= 1 && num <= 3999, "Input must be in [1, 3999]");

        // Define Roman numeral mappings and keys
        uint256[13] memory keys = [uint256(1000), 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
        string[13] memory values = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"];

        // Initialize dynamic bytes array (32 bytes to be safe)
        bytes memory result = new bytes(32);
        uint resultIndex = 0;

        // Process number directly with weights
        uint temp = num;
        //emit Debug(temp); // Debug input
        uint16[4] memory weights = [1000, 100, 10, 1];
        for (uint i = 0; i < 4 && temp > 0; i++) {
            uint value = (temp / weights[i]) * weights[i]; // e.g., (685 / 100) * 100 = 600
            if (value > 0) {
                //emit Debug(value); // Debug current value
                for (uint j = 0; j < 13; j++) {
                    while (value >= keys[j]) {
                        bytes memory symbol = bytes(values[j]);
                        for (uint k = 0; k < symbol.length; k++) {
                            result[resultIndex++] = symbol[k];
                        }
                        value -= keys[j];
                    }
                }
                temp = temp % weights[i]; // Update remaining value
            }
        }

        // Trim result to actual length
        bytes memory trimmedResult = new bytes(resultIndex);
        for (uint i = 0; i < resultIndex; i++) {
            trimmedResult[i] = result[i];
        }

        return string(trimmedResult);
    }
}