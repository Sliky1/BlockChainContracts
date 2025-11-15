// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title AuctionNFT
 * @dev OpenZeppelin 
 */
contract AuctionNFT is 
    Initializable, 
    ERC721Upgradeable, 
    OwnableUpgradeable, 
    UUPSUpgradeable 
{
    uint256 private _nextTokenId;
    
    // NFT元数据存储
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public royalties;
    
    uint256 public constant MAX_ROYALTY = 1000; // 10%

    // 事件
    event NFTMinted(uint256 indexed tokenId, address indexed creator, string tokenURI, uint256 royalty);
    event RoyaltySet(uint256 indexed tokenId, uint256 royalty);

    // 错误定义
    error RoyaltyTooHigh();
    error TokenNotExists();
    error NotCreator();
    error ArraysLengthMismatch();
    error EmptyArrays();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name, string memory symbol) external initializer {
        __ERC721_init(name, symbol);
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        _nextTokenId = 1; // 从1开始
    }

    /**
     * @dev 铸造NFT
     */
    function mintNFT(address to, string memory uri, uint256 royalty) public returns (uint256) {
        if (royalty > MAX_ROYALTY) revert RoyaltyTooHigh();

        uint256 tokenId = _nextTokenId++;
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        
        creators[tokenId] = msg.sender;
        royalties[tokenId] = royalty;
        
        emit NFTMinted(tokenId, msg.sender, uri, royalty);
        
        return tokenId;
    }

    /**
     * @dev 批量铸造NFT
     */
    function batchMintNFT(
        address to,
        string[] memory tokenURIs,
        uint256[] memory royaltyArray
    ) external returns (uint256[] memory) {
        if (tokenURIs.length != royaltyArray.length) revert ArraysLengthMismatch();
        if (tokenURIs.length == 0) revert EmptyArrays();
        
        uint256[] memory tokenIds = new uint256[](tokenURIs.length);
        
        for (uint256 i = 0; i < tokenURIs.length; i++) {
            tokenIds[i] = mintNFT(to, tokenURIs[i], royaltyArray[i]);
        }
        
        return tokenIds;
    }

    /**
     * @dev 设置版税
     */
    function setRoyalty(uint256 tokenId, uint256 royalty) external {
        if (!exists(tokenId)) revert TokenNotExists();
        if (creators[tokenId] != msg.sender) revert NotCreator();
        if (royalty > MAX_ROYALTY) revert RoyaltyTooHigh();
        
        royalties[tokenId] = royalty;
        emit RoyaltySet(tokenId, royalty);
    }

    /**
     * @dev 手动设置Token URI
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev 获取Token URI - 重写ERC721的方法
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // OpenZeppelin 5.x的新方法
        return _tokenURIs[tokenId];
    }

    /**
     * @dev 获取版税信息 (EIP-2981标准)
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) 
        external 
        view 
        returns (address receiver, uint256 royaltyAmount) 
    {
        if (!exists(tokenId)) revert TokenNotExists();
        
        receiver = creators[tokenId];
        royaltyAmount = (salePrice * royalties[tokenId]) / 10000;
    }

    /**
     * @dev 获取版税信息（兼容旧接口）
     */
    function getRoyaltyInfo(uint256 tokenId, uint256 salePrice) 
        external 
        view 
        returns (address creator, uint256 royaltyAmount) 
    {
        if (!exists(tokenId)) revert TokenNotExists();
        
        creator = creators[tokenId];
        royaltyAmount = (salePrice * royalties[tokenId]) / 10000;
    }

    /**
     * @dev 获取当前token ID
     */
    function getCurrentTokenId() external view returns (uint256) {
        return _nextTokenId;
    }

    /**
     * @dev 检查token是否存在
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev 重写_update方法来处理token转移和销毁时的清理
     * 这是OpenZeppelin 5.x的新模式，替代了_burn重写
     */
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        
        // 如果是销毁操作（to == address(0)），清理相关数据
        if (to == address(0) && from != address(0)) {
            delete _tokenURIs[tokenId];
            delete creators[tokenId];
            delete royalties[tokenId];
        }
        
        return super._update(to, tokenId, auth);
    }

    /**
     * @dev 支持EIP-2981版税标准
     */
    function supportsInterface(bytes4 interfaceId)
        public 
        view 
        override
        returns (bool)
    {
        // EIP-2981版税标准接口ID: 0x2a55205a
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    /**
     * @dev 授权升级 - 只有owner可以升级
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}