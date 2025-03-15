// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // Import ReentrancyGuard from OpenZeppelin for production use

/**
 * @title ReceivePayment
 * @dev This contract allows receiving payments in Ether.
 */
contract ReceivePayment {
    // State variable to store the owner's address
    address private _owner;
    // State variable to store the contract's balance
    uint256 private _balance;

    /**
     * @dev Constructor that sets the owner of the contract.
     */
    constructor() {
        _owner = msg.sender;
        _balance = 0;
    }

    /**
     * @dev Modifier to check if the caller is the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    /**
     * @dev Fallback function to receive Ether.
     * This function is called when Ether is sent to the contract
     * without any data or with unrecognized data.
     * It is marked as `payable` to allow the contract to receive Ether.
     */
    receive() external payable {
        _balance += msg.value;
    }

    /**
     * @dev Function to withdraw all Ether from the contract.
     * Can only be called by the contract owner.
     */
    function withdraw() external onlyOwner {
        // Get the contract balance
        uint256 amount = _balance;
        _balance = 0;

        // Transfer the Ether to the owner
        (bool success, ) = _owner.call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    /**
     * @dev Function to return the address of the contract owner.
     * @return address The address of the contract owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
    /*
    * @dev Function to get the contract's balance.
    * @return uint256 The contract's balance in Wei.
    */
    // function getBalance() public view returns (uint256) {
    //     return address(this).balance;
    // }
}
