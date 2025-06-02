// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MergeSortedArray {
    // Debug event to track values
    function mergeSortedArrays(uint[] memory nums1, uint[] memory nums2) 
        public pure returns (uint[] memory) {

        uint m = nums1.length;
        uint n = nums2.length;
        // Create new array for result
        uint[] memory result = new uint[](m + n);
        uint p1 = 0; // Pointer for nums1
        uint p2 = 0; // Pointer for nums2
        uint p = 0;  // Pointer for result

        // Merge while both arrays have elements
        while (p1 < m && p2 < n) {
            if (nums1[p1] <= nums2[p2]) {
                result[p] = nums1[p1];
                p1++;
            } else {
                result[p] = nums2[p2];
                p2++;
            }
            p++;
        }

        // Copy remaining elements from nums1
        while (p1 < m) {
            result[p] = nums1[p1];
            p1++;
            p++;
        }

        // Copy remaining elements from nums2
        while (p2 < n) {
            result[p] = nums2[p2];
            p2++;
            p++;
        }

        return result;
    }
}