//### ✅ 作业 1：ERC20 代币
//任务：参考 openzeppelin-contracts/contracts/token/ERC20/IERC20.sol实现一个简单的 ERC20 代币合约。要求：
//1. 合约包含以下标准 ERC20 功能：
//- balanceOf：查询账户余额。
//- transfer：转账。
//- approve 和 transferFrom：授权和代扣转账。
//2. 使用 event 记录转账和授权操作。
//3. 提供 mint 函数，允许合约所有者增发代币。
//提示：
//- 使用 mapping 存储账户余额和授权信息。
//- 使用 event 定义 Transfer 和 Approval 事件。
// 4. 部署到sepolia 测试网，导入到自己的钱包

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev ERC20 代币标准的接口。
 * 这是 OpenZeppelin Contracts (contracts/token/ERC20/IERC20.sol) 的一个参考实现。
 */
interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract SimpleERC20 is IERC20 {
    // 状态变量
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address private _owner;

    modifier onlyOwner() {
        require(owner() == msg.sender, "SimpleERC20: caller is not the owner");
        _;
    }

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _owner = msg.sender;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function name() public view returns (string memory) {
        return _name;
    }


    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view override returns (uint256) {
        return _allowances[tokenOwner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "SimpleERC20: transfer amount exceeds allowance");
        
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, currentAllowance - amount);
        
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "SimpleERC20: transfer from the zero address");
        require(to != address(0), "SimpleERC20: transfer to the zero address");
        require(_balances[from] >= amount, "SimpleERC20: transfer amount exceeds balance");

        _balances[from] -= amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _approve(address tokenOwner, address spender, uint256 amount) internal {
        require(tokenOwner != address(0), "SimpleERC20: approve from the zero address");
        require(spender != address(0), "SimpleERC20: approve to the zero address");

        _allowances[tokenOwner][spender] = amount;
        emit Approval(tokenOwner, spender, amount);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "SimpleERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[to] += amount;
        
        emit Transfer(address(0), to, amount);
    }
}
