// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Auction.sol";

/**
 * @title AuctionFactory
 * @dev 拍卖工厂合约，使用简化的工厂模式管理拍卖
 */
contract AuctionFactory is 
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable 
{
    // 拍卖实现地址
    address public auctionImplementation;
    
    // 平台费用设置
    uint256 public platformFee; // 基点
    address public platformFeeRecipient;
    
    // 支持的支付代币
    struct PaymentToken {
        bool isSupported;
        address priceFeed;
        uint8 decimals;
        string symbol;
    }
    
    mapping(address => PaymentToken) public paymentTokens;
    address[] public supportedTokensList;
    
    // 拍卖存储
    mapping(bytes32 => address) public auctions; // keccak256(nftContract, tokenId) => auction
    address[] public allAuctions;
    mapping(address => address[]) public userAuctions; // seller => auctions
    
    // 拍卖限制
    uint256 public constant MIN_AUCTION_DURATION = 1 hours;
    uint256 public constant MAX_AUCTION_DURATION = 30 days;
    uint256 public constant MAX_PLATFORM_FEE = 1000; // 10%

    // 事件
    event AuctionCreated(
        address indexed auction,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        uint256 startingPrice,
        uint256 reservePrice,
        uint256 duration
    );
    
    event PaymentTokenAdded(address indexed token, address indexed priceFeed, string symbol);
    event PaymentTokenRemoved(address indexed token);
    event PlatformFeeUpdated(uint256 oldFee, uint256 newFee);
    event AuctionImplementationUpdated(address oldImpl, address newImpl);

    // 错误定义
    error InvalidImplementation();
    error InvalidFeeRecipient();
    error FeeTooHigh();
    error AuctionExists();
    error NotNFTOwner();
    error InvalidDuration();
    error InvalidPrice();
    error NFTNotApproved();
    error AuctionNotFound();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _auctionImplementation,
        uint256 _platformFee,
        address _platformFeeRecipient
    ) external initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        if (_auctionImplementation == address(0)) revert InvalidImplementation();
        if (_platformFeeRecipient == address(0)) revert InvalidFeeRecipient();
        if (_platformFee > MAX_PLATFORM_FEE) revert FeeTooHigh();

        auctionImplementation = _auctionImplementation;
        platformFee = _platformFee;
        platformFeeRecipient = _platformFeeRecipient;

        // 默认添加ETH支持
        _addPaymentToken(
            address(0), 
            0x694AA1769357215DE4FAC081bf1f309aDC325306, // Sepolia ETH/USD
            18, 
            "ETH"
        );
    }

    /**
     * @dev 创建拍卖
     */
    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startingPrice,
        uint256 reservePrice,
        uint256 duration
    ) external nonReentrant returns (address auctionAddress) {
        // 验证输入参数
        if (duration < MIN_AUCTION_DURATION || duration > MAX_AUCTION_DURATION) {
            revert InvalidDuration();
        }
        if (startingPrice == 0) revert InvalidPrice();

        IERC721 nft = IERC721(nftContract);
        
        // 验证NFT所有权
        if (nft.ownerOf(tokenId) != msg.sender) revert NotNFTOwner();
        
        // 验证NFT已授权
        if (nft.getApproved(tokenId) != address(this) && 
            !nft.isApprovedForAll(msg.sender, address(this))) {
            revert NFTNotApproved();
        }

        // 检查拍卖是否已存在
        bytes32 auctionKey = keccak256(abi.encodePacked(nftContract, tokenId));
        if (auctions[auctionKey] != address(0)) revert AuctionExists();

        // 创建拍卖代理
        bytes memory initData = abi.encodeCall(
            Auction.initialize,
            (
                nftContract,
                tokenId,
                msg.sender,
                startingPrice,
                reservePrice,
                duration,
                platformFee,
                platformFeeRecipient,
                address(this)
            )
        );

        ERC1967Proxy proxy = new ERC1967Proxy(auctionImplementation, initData);
        auctionAddress = address(proxy);

        // 存储拍卖信息
        auctions[auctionKey] = auctionAddress;
        allAuctions.push(auctionAddress);
        userAuctions[msg.sender].push(auctionAddress);

        // 转移NFT到拍卖合约
        nft.safeTransferFrom(msg.sender, auctionAddress, tokenId);

        // 配置支付代币
        _configureAuctionPaymentTokens(auctionAddress);

        emit AuctionCreated(
            auctionAddress,
            nftContract,
            tokenId,
            msg.sender,
            startingPrice,
            reservePrice,
            duration
        );
    }

    /**
     * @dev 配置拍卖的支付代币
     */
    function _configureAuctionPaymentTokens(address auctionAddress) internal {
        Auction auction = Auction(auctionAddress);
        
        for (uint256 i = 0; i < supportedTokensList.length; i++) {
            address token = supportedTokensList[i];
            PaymentToken memory tokenInfo = paymentTokens[token];
            
            if (tokenInfo.isSupported && token != address(0)) {
                auction.addPaymentToken(token, tokenInfo.priceFeed);
            }
        }
    }

    /**
     * @dev 添加支付代币
     */
    function addPaymentToken(
        address token,
        address priceFeed,
        uint8 decimals,
        string calldata symbol
    ) external onlyOwner {
        _addPaymentToken(token, priceFeed, decimals, symbol);
    }

    function _addPaymentToken(
        address token,
        address priceFeed,
        uint8 decimals,
        string memory symbol
    ) internal {
        if (priceFeed == address(0)) revert InvalidImplementation();
        
        if (!paymentTokens[token].isSupported) {
            supportedTokensList.push(token);
        }
        
        paymentTokens[token] = PaymentToken({
            isSupported: true,
            priceFeed: priceFeed,
            decimals: decimals,
            symbol: symbol
        });
        
        emit PaymentTokenAdded(token, priceFeed, symbol);
    }

    /**
     * @dev 移除支付代币
     */
    function removePaymentToken(address token) external onlyOwner {
        if (token == address(0)) revert InvalidImplementation(); // 不能移除ETH
        
        paymentTokens[token].isSupported = false;
        
        // 从列表中移除
        for (uint256 i = 0; i < supportedTokensList.length; i++) {
            if (supportedTokensList[i] == token) {
                supportedTokensList[i] = supportedTokensList[supportedTokensList.length - 1];
                supportedTokensList.pop();
                break;
            }
        }
        
        emit PaymentTokenRemoved(token);
    }

    /**
     * @dev 更新平台费用
     */
    function updatePlatformFee(uint256 newFee) external onlyOwner {
        if (newFee > MAX_PLATFORM_FEE) revert FeeTooHigh();
        
        uint256 oldFee = platformFee;
        platformFee = newFee;
        
        emit PlatformFeeUpdated(oldFee, newFee);
    }

    /**
     * @dev 更新费用接收者
     */
    function updatePlatformFeeRecipient(address newRecipient) external onlyOwner {
        if (newRecipient == address(0)) revert InvalidFeeRecipient();
        platformFeeRecipient = newRecipient;
    }

    /**
     * @dev 更新拍卖实现
     */
    function updateAuctionImplementation(address newImplementation) external onlyOwner {
        if (newImplementation == address(0)) revert InvalidImplementation();
        
        address oldImpl = auctionImplementation;
        auctionImplementation = newImplementation;
        
        emit AuctionImplementationUpdated(oldImpl, newImplementation);
    }

    /**
     * @dev 获取拍卖地址
     */
    function getAuction(address nftContract, uint256 tokenId) external view returns (address) {
        bytes32 auctionKey = keccak256(abi.encodePacked(nftContract, tokenId));
        return auctions[auctionKey];
    }

    /**
     * @dev 获取用户拍卖列表
     */
    function getUserAuctions(address user) external view returns (address[] memory) {
        return userAuctions[user];
    }

    /**
     * @dev 获取所有拍卖
     */
    function getAllAuctions() external view returns (address[] memory) {
        return allAuctions;
    }

    /**
     * @dev 获取支持的代币列表
     */
    function getSupportedTokens() external view returns (address[] memory) {
        return supportedTokensList;
    }

    /**
     * @dev 获取拍卖统计
     */
    function getAuctionStats() external view returns (
        uint256 totalAuctions,
        uint256 supportedTokensCount
    ) {
        return (allAuctions.length, supportedTokensList.length);
    }

    /**
     * @dev 检查代币是否支持
     */
    function isTokenSupported(address token) external view returns (bool) {
        return paymentTokens[token].isSupported;
    }

    /**
     * @dev 授权升级
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}