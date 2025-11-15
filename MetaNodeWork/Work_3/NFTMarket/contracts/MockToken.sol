// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockToken
 * @dev 简化的测试代币，支持水龙头功能
 */
contract MockToken is ERC20, Ownable {
    uint8 private _decimals;
    uint256 public constant FAUCET_AMOUNT = 10000; // 水龙头每次给的数量
    uint256 public faucetCooldown = 1 hours; // 水龙头冷却时间
    
    mapping(address => uint256) public lastFaucetTime;

    event FaucetUsed(address indexed user, uint256 amount);

    error FaucetCooldownActive();
    error AmountTooLarge();

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_,
        uint256 initialSupply
    ) ERC20(name, symbol) Ownable(msg.sender) {
        _decimals = decimals_;
        _mint(msg.sender, initialSupply * 10**decimals_);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev 水龙头 - 获取测试代币（有冷却时间）
     */
    function faucet() external {
        if (block.timestamp < lastFaucetTime[msg.sender] + faucetCooldown) {
            revert FaucetCooldownActive();
        }
        
        uint256 amount = FAUCET_AMOUNT * 10**_decimals;
        lastFaucetTime[msg.sender] = block.timestamp;
        
        _mint(msg.sender, amount);
        emit FaucetUsed(msg.sender, amount);
    }

    /**
     * @dev 直接获取代币（指定数量，有限制）
     */
    function faucet(uint256 amount) external {
        uint256 maxAmount = FAUCET_AMOUNT * 10**_decimals;
        if (amount > maxAmount) revert AmountTooLarge();
        
        _mint(msg.sender, amount);
        emit FaucetUsed(msg.sender, amount);
    }

    /**
     * @dev 铸造代币给指定地址（仅owner）
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev 设置水龙头冷却时间（仅owner）
     */
    function setFaucetCooldown(uint256 newCooldown) external onlyOwner {
        faucetCooldown = newCooldown;
    }

    /**
     * @dev 获取下次可以使用水龙头的时间
     */
    function getNextFaucetTime(address user) external view returns (uint256) {
        return lastFaucetTime[user] + faucetCooldown;
    }

    /**
     * @dev 检查是否可以使用水龙头
     */
    function canUseFaucet(address user) external view returns (bool) {
        return block.timestamp >= lastFaucetTime[user] + faucetCooldown;
    }
}