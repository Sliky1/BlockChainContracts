// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Auction
 * @dev 简化版拍卖合约，用固定汇率避免价格预言机问题
 */
contract Auction is 
    Initializable, 
    ReentrancyGuardUpgradeable, 
    OwnableUpgradeable, 
    UUPSUpgradeable 
{
    using SafeERC20 for IERC20;

    // 拍卖状态
    enum AuctionState { Active, Ended, Cancelled }

    // 出价信息
    struct BidInfo {
        address bidder;
        uint256 amount;
        address paymentToken; // address(0) for ETH
        uint256 usdValue;
        uint256 timestamp;
    }

    // 核心变量
    IERC721 public nftContract;
    uint256 public tokenId;
    address public seller;
    uint256 public startingPrice; // 起拍价 (USD)
    uint256 public reservePrice;  // 保留价 (USD)
    uint256 public auctionEndTime;
    AuctionState public auctionState;
    
    // 出价状态
    BidInfo public highestBid;
    mapping(address => mapping(address => uint256)) public pendingReturns;
    
    // 支付配置
    mapping(address => bool) public supportedTokens;
    
    // 费用配置
    uint256 public platformFee; // 基点 (100 = 1%)
    address public platformFeeRecipient;
    address public factory;

    // 常量
    uint256 public constant BID_EXTENSION_TIME = 10 minutes;
    uint256 public constant MIN_BID_INCREMENT = 500; // 5%
    uint256 public constant ETH_USD_RATE = 2000; // 1 ETH = 2000 USD (测试用固定汇率)

    // 事件
    event AuctionCreated(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 startingPrice,
        uint256 reservePrice,
        uint256 auctionEndTime
    );
    
    event BidPlaced(
        address indexed bidder,
        uint256 amount,
        address paymentToken,
        uint256 usdValue,
        uint256 newEndTime
    );
    
    event AuctionEnded(
        address indexed winner,
        uint256 winningBid,
        address paymentToken
    );
    
    event AuctionCancelled();

    // 错误定义
    error OnlyFactory();
    error AuctionNotActive();
    error AuctionEnd();
    error BidTooLow();
    error InsufficientIncrement();
    error NoFundsToWithdraw();
    error InvalidInput();

    // 修饰符
    modifier onlyFactory() {
        if (msg.sender != factory) revert OnlyFactory();
        _;
    }

    modifier onlyActiveBidding() {
        if (auctionState != AuctionState.Active) revert AuctionNotActive();
        if (block.timestamp >= auctionEndTime) revert AuctionEnd();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _nftContract,
        uint256 _tokenId,
        address _seller,
        uint256 _startingPrice,
        uint256 _reservePrice,
        uint256 _duration,
        uint256 _platformFee,
        address _platformFeeRecipient,
        address _factory
    ) external initializer {
        __ReentrancyGuard_init();
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        if (_nftContract == address(0) || _seller == address(0)) revert InvalidInput();
        if (_startingPrice == 0 || _duration == 0) revert InvalidInput();
        if (_platformFee > 1000) revert InvalidInput(); // 最大10%

        nftContract = IERC721(_nftContract);
        tokenId = _tokenId;
        seller = _seller;
        startingPrice = _startingPrice;
        reservePrice = _reservePrice;
        auctionEndTime = block.timestamp + _duration;
        auctionState = AuctionState.Active;
        platformFee = _platformFee;
        platformFeeRecipient = _platformFeeRecipient;
        factory = _factory;

        // 默认支持ETH
        supportedTokens[address(0)] = true;

        emit AuctionCreated(
            _nftContract,
            _tokenId,
            _seller,
            _startingPrice,
            _reservePrice,
            auctionEndTime
        );
    }

    /**
     * @dev 添加支付代币（简化版）
     */
    function addPaymentToken(address token, address) external onlyFactory {
        supportedTokens[token] = true;
    }

    /**
     * @dev ETH出价
     */
    function bidWithETH() external payable onlyActiveBidding nonReentrant {
        if (msg.value == 0) revert InvalidInput();
        uint256 usdValue = _convertToUSD(address(0), msg.value);
        _placeBid(msg.sender, msg.value, address(0), usdValue);
    }

    /**
     * @dev ERC20代币出价
     */
    function bidWithToken(address token, uint256 amount) 
        external 
        onlyActiveBidding 
        nonReentrant 
    {
        if (token == address(0) || !supportedTokens[token] || amount == 0) {
            revert InvalidInput();
        }
        
        uint256 usdValue = _convertToUSD(token, amount);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _placeBid(msg.sender, amount, token, usdValue);
    }

    /**
     * @dev 内部出价逻辑
     */
    function _placeBid(
        address bidder, 
        uint256 amount, 
        address paymentToken, 
        uint256 usdValue
    ) internal {
        if (usdValue < startingPrice) revert BidTooLow();
        
        // 检查最小增幅
        if (highestBid.bidder != address(0)) {
            uint256 minIncrement = (highestBid.usdValue * MIN_BID_INCREMENT) / 10000;
            if (usdValue < highestBid.usdValue + minIncrement) {
                revert InsufficientIncrement();
            }
            
            // 记录前一个出价者的退款
            pendingReturns[highestBid.bidder][highestBid.paymentToken] += highestBid.amount;
        }
        
        // 更新最高出价
        highestBid = BidInfo({
            bidder: bidder,
            amount: amount,
            paymentToken: paymentToken,
            usdValue: usdValue,
            timestamp: block.timestamp
        });
        
        // 拍卖延时逻辑
        uint256 newEndTime = auctionEndTime;
        if (auctionEndTime - block.timestamp < BID_EXTENSION_TIME) {
            newEndTime = block.timestamp + BID_EXTENSION_TIME;
            auctionEndTime = newEndTime;
        }
        
        emit BidPlaced(bidder, amount, paymentToken, usdValue, newEndTime);
    }

    /**
     * @dev 结束拍卖
     */
    function endAuction() external nonReentrant {
        if (auctionState != AuctionState.Active) revert AuctionNotActive();
        if (block.timestamp < auctionEndTime) revert InvalidInput();
        
        auctionState = AuctionState.Ended;
        
        if (highestBid.bidder != address(0) && highestBid.usdValue >= reservePrice) {
            // 转移NFT给获胜者
            nftContract.safeTransferFrom(address(this), highestBid.bidder, tokenId);
            
            // 分配资金
            _distributeFunds();
            
            emit AuctionEnded(highestBid.bidder, highestBid.amount, highestBid.paymentToken);
        } else {
            // 拍卖失败 - 退还最高出价
            if (highestBid.bidder != address(0)) {
                pendingReturns[highestBid.bidder][highestBid.paymentToken] += highestBid.amount;
            }
            emit AuctionCancelled();
        }
    }

    /**
     * @dev 分配资金
     */
    function _distributeFunds() internal {
        uint256 totalAmount = highestBid.amount;
        address paymentToken = highestBid.paymentToken;
        
        // 计算费用
        uint256 feeAmount = (totalAmount * platformFee) / 10000;
        uint256 sellerAmount = totalAmount - feeAmount;
        
        if (paymentToken == address(0)) {
            // ETH
            if (feeAmount > 0) {
                payable(platformFeeRecipient).transfer(feeAmount);
            }
            payable(seller).transfer(sellerAmount);
        } else {
            // ERC20
            if (feeAmount > 0) {
                IERC20(paymentToken).safeTransfer(platformFeeRecipient, feeAmount);
            }
            IERC20(paymentToken).safeTransfer(seller, sellerAmount);
        }
    }

    /**
     * @dev 提取待退还资金
     */
    function withdraw(address token) external nonReentrant {
        uint256 amount = pendingReturns[msg.sender][token];
        if (amount == 0) revert NoFundsToWithdraw();
        
        pendingReturns[msg.sender][token] = 0;
        
        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(token).safeTransfer(msg.sender, amount);
        }
    }

    /**
     * @dev 取消拍卖（仅在无人出价时）
     */
    function cancelAuction() external {
        if (msg.sender != seller) revert InvalidInput();
        if (auctionState != AuctionState.Active) revert AuctionNotActive();
        if (highestBid.bidder != address(0)) revert InvalidInput();
        
        auctionState = AuctionState.Cancelled;
        emit AuctionCancelled();
    }

    /**
     * @dev 简化的USD转换（固定汇率）
     */
    function _convertToUSD(address token, uint256 amount) internal pure returns (uint256) {
        if (token == address(0)) {
            // ETH: 使用固定汇率 1 ETH = 2000 USD
            return amount * ETH_USD_RATE;
        } else {
            // ERC20: 假设 1:1 USD (可以根据需要调整)
            return amount;
        }
    }

    /**
     * @dev 获取拍卖信息
     */
    function getAuctionInfo() external view returns (
        address _nftContract,
        uint256 _tokenId,
        address _seller,
        uint256 _startingPrice,
        uint256 _reservePrice,
        uint256 _auctionEndTime,
        AuctionState _auctionState,
        BidInfo memory _highestBid
    ) {
        return (
            address(nftContract),
            tokenId,
            seller,
            startingPrice,
            reservePrice,
            auctionEndTime,
            auctionState,
            highestBid
        );
    }

    /**
     * @dev 获取剩余时间
     */
    function getTimeLeft() external view returns (uint256) {
        if (block.timestamp >= auctionEndTime) return 0;
        return auctionEndTime - block.timestamp;
    }

    /**
     * @dev 获取待退还金额
     */
    function getPendingReturns(address bidder, address token) external view returns (uint256) {
        return pendingReturns[bidder][token];
    }

    /**
     * @dev ERC721接收回调
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev 授权升级
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}