// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title BeggingContract
 * @dev 一个允许用户捐赠以太币的智能合约
 */
contract BeggingContract {
    // 合约所有者
    address public owner;
    
    // 记录每个捐赠者的总捐赠金额
    mapping(address => uint256) public donations;
    
    // 记录所有捐赠者的地址
    address[] public donors;
    
    // 记录捐赠者是否已经在donors数组中
    mapping(address => bool) public isDonor;
    
    // 合约的总余额
    uint256 public totalDonations;
    
    // 捐赠事件
    event Donation(address indexed donor, uint256 amount, uint256 timestamp);
    
    // 提取事件
    event Withdrawal(address indexed owner, uint256 amount, uint256 timestamp);
    
    /**
     * @dev 构造函数，设置合约所有者
     */
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev 只有合约所有者可以调用的修饰符
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /**
     * @dev 捐赠函数，允许用户向合约发送以太币
     */
    function donate() external payable {
        require(msg.value > 0, "Donation amount must be greater than 0");
        
        _processDonation(msg.sender, msg.value);
    }
    
    /**
     * @dev 内部函数处理捐赠逻辑
     */
    function _processDonation(address donor, uint256 amount) internal {
        // 如果是新的捐赠者，添加到donors数组
        if (!isDonor[donor]) {
            donors.push(donor);
            isDonor[donor] = true;
        }
        
        // 记录捐赠金额
        donations[donor] += amount;
        totalDonations += amount;
        
        // 触发捐赠事件
        emit Donation(donor, amount, block.timestamp);
    }
    
    /**
     * @dev 允许直接向合约发送以太币
     */
    receive() external payable {
        require(msg.value > 0, "Donation amount must be greater than 0");
        _processDonation(msg.sender, msg.value);
    }
    
    /**
     * @dev fallback函数
     */
    fallback() external payable {
        require(msg.value > 0, "Donation amount must be greater than 0");
        _processDonation(msg.sender, msg.value);
    }
    
    /**
     * @dev 提取函数，只有合约所有者可以提取所有资金
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        // 转账给合约所有者
        payable(owner).transfer(balance);
        
        // 触发提取事件
        emit Withdrawal(owner, balance, block.timestamp);
    }
    
    /**
     * @dev 查询某个地址的捐赠金额
     * @param donor 捐赠者地址
     * @return 捐赠金额
     */
    function getDonation(address donor) external view returns (uint256) {
        return donations[donor];
    }
    
    /**
     * @dev 获取合约余额
     * @return 合约当前余额
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev 获取捐赠者总数
     * @return 捐赠者数量
     */
    function getDonorCount() external view returns (uint256) {
        return donors.length;
    }
    
    /**
     * @dev 获取所有捐赠者地址
     * @return 捐赠者地址数组
     */
    function getAllDonors() external view returns (address[] memory) {
        return donors;
    }
    
    /**
     * @dev 获取捐赠排行榜（前3名）
     * @return 前3名捐赠者地址和金额
     */
    function getTopDonors() external view returns (address[] memory, uint256[] memory) {
        uint256 donorCount = donors.length;
        if (donorCount == 0) {
            return (new address[](0), new uint256[](0));
        }
        
        // 创建临时数组存储地址和金额
        address[] memory tempAddresses = new address[](donorCount);
        uint256[] memory tempAmounts = new uint256[](donorCount);
        
        // 复制数据
        for (uint256 i = 0; i < donorCount; i++) {
            tempAddresses[i] = donors[i];
            tempAmounts[i] = donations[donors[i]];
        }
        
        // 简单的冒泡排序（降序）
        for (uint256 i = 0; i < donorCount - 1; i++) {
            for (uint256 j = 0; j < donorCount - i - 1; j++) {
                if (tempAmounts[j] < tempAmounts[j + 1]) {
                    // 交换金额
                    uint256 tempAmount = tempAmounts[j];
                    tempAmounts[j] = tempAmounts[j + 1];
                    tempAmounts[j + 1] = tempAmount;
                    
                    // 交换地址
                    address tempAddress = tempAddresses[j];
                    tempAddresses[j] = tempAddresses[j + 1];
                    tempAddresses[j + 1] = tempAddress;
                }
            }
        }
        
        // 返回前3名（如果少于3个捐赠者，返回全部）
        uint256 topCount = donorCount > 3 ? 3 : donorCount;
        address[] memory topAddresses = new address[](topCount);
        uint256[] memory topAmounts = new uint256[](topCount);
        
        for (uint256 i = 0; i < topCount; i++) {
            topAddresses[i] = tempAddresses[i];
            topAmounts[i] = tempAmounts[i];
        }
        
        return (topAddresses, topAmounts);
    }
    
    /**
     * @dev 检查某个地址是否为捐赠者
     * @param donor 要检查的地址
     * @return 是否为捐赠者
     */
    function isDonorAddress(address donor) external view returns (bool) {
        return isDonor[donor];
    }
}