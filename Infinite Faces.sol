// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract OptimizedRandomAvatars is ERC721Enumerable, Ownable, VRFConsumerBaseV2 {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MINT_PRICE = 0.05 ether;

    string public immutable baseURI;
    mapping(uint256 => string) private _tokenURIs;

    // 特征定义（链下生成元数据）
    string[] public eyes = ["eyes1", "eyes2", "eyes3"];
    string[] public hairs = ["hair1", "hair2", "hair3"];
    string[] public backgrounds = ["bg1", "bg2", "bg3"];

    VRFCoordinatorV2Interface COORDINATOR;
    uint64 immutable s_subscriptionId;
    bytes32 immutable s_keyHash;
    uint32 immutable s_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint8 private constant NUM_WORDS = 1;

    mapping(uint256 => uint256) public requestIdToTokenId;

    event Minted(uint256 indexed tokenId, address indexed owner);
    event MetadataUpdated(uint256 indexed tokenId, string metadataURI);
    event RandomWordsRequested(uint256 indexed requestId, uint256 indexed tokenId);
    event RandomWordsFulfilled(uint256 indexed requestId, uint256 indexed tokenId, uint256 randomNumber);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint64 subscriptionId,
        bytes32 keyHash,
        address vrfCoordinatorV2
    ) ERC721(_name, _symbol) VRFConsumerBaseV2(vrfCoordinatorV2) {
        baseURI = _baseURI;
        s_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        s_callbackGasLimit = 100000; // 默认值，可以根据需要调整
    }

    function requestRandomWords(uint256 tokenId) internal returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            REQUEST_CONFIRMATIONS,
            s_callbackGasLimit,
            NUM_WORDS
        );
        requestIdToTokenId[requestId] = tokenId;
        emit RandomWordsRequested(requestId, tokenId);
        return requestId;
    }

    function mint() public payable {
        require(totalSupply() < MAX_SUPPLY, "Max supply reached");
        require(msg.value >= MINT_PRICE, "Insufficient funds");

        uint256 tokenId = totalSupply() + 1;
        _safeMint(msg.sender, tokenId);
        emit Minted(tokenId, msg.sender);
        requestRandomWords(tokenId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(requestIdToTokenId[requestId] != 0, "Invalid request ID");
        uint256 tokenId = requestIdToTokenId[requestId];
        uint256 randomNumber = randomWords[0];
        string memory metadataURI = generateMetadataURI(tokenId, randomNumber); // 链下生成元数据
        _setTokenURI(tokenId, metadataURI);
        emit MetadataUpdated(tokenId, metadataURI);
        emit RandomWordsFulfilled(requestId, tokenId, randomNumber);
        delete requestIdToTokenId[requestId];
    }

    function generateMetadataURI(uint256 tokenId, uint256 randomNumber) internal pure returns (string memory) {
        // 链下生成元数据，返回 IPFS URI
        // 这里只是一个示例，实际需要链下服务生成 JSON 文件并上传 IPFS
        string memory ipfsHash = Strings.toHexString(randomNumber); // 示例：使用随机数生成 IPFS 哈希
        return string(abi.encodePacked("ipfs://", ipfsHash, ".json"));
    }

    function _setTokenURI(uint256 tokenId, string memory metadataURI) internal {
        _tokenURIs[tokenId] = metadataURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdrawal failed");
    }
}