// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BinarySearch {
    function binarySearch(uint[] memory nums, uint target) 
        public pure returns (uint) {
        // Handle empty array
        if (nums.length == 0) {
            return type(uint256).max;
        }

        uint left = 0;
        uint right = nums.length - 1;

        while (left <= right) {
            uint mid = (left + right) / 2;
            if (nums[mid] == target) {
                return mid;
            } else if (nums[mid] < target) {
                left = mid + 1;
            } else {
                right = mid - 1;
            }
        }

        return type(uint256).max;
    }
}