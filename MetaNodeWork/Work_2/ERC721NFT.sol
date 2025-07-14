// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract MyNFT is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    
    // 用于生成递增的NFT ID
    Counters.Counter private _tokenIdCounter;
    
    // 事件：NFT铸造成功
    event NFTMinted(address indexed to, uint256 indexed tokenId, string uri);
    
    constructor() ERC721("MyAwesomeNFT", "MANFT") Ownable(msg.sender) {
        // 从ID 1开始，避免使用0
        _tokenIdCounter.increment();
    }
    
    function mintNFT(address to, string memory uri) public onlyOwner returns (uint256) {
        require(to != address(0), "MyNFT: mint to the zero address");
        require(bytes(uri).length > 0, "MyNFT: tokenURI cannot be empty");
        
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        
        emit NFTMinted(to, tokenId, uri);
        
        return tokenId;
    }
    
    function publicMint(string memory uri) public returns (uint256) {
        require(bytes(uri).length > 0, "MyNFT: tokenURI cannot be empty");
        
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        
        emit NFTMinted(msg.sender, tokenId, uri);
        
        return tokenId;
    }
    

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current() - 1;
    }
    
    function nextTokenId() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    

    function batchMint(address to, string[] memory uris) public onlyOwner {
        require(to != address(0), "MyNFT: mint to the zero address");
        require(uris.length > 0, "MyNFT: tokenURIs array cannot be empty");
        require(uris.length <= 10, "MyNFT: batch mint limited to 10 NFTs");
        
        for (uint256 i = 0; i < uris.length; i++) {
            require(bytes(uris[i]).length > 0, "MyNFT: tokenURI cannot be empty");
            mintNFT(to, uris[i]);
        }
    }
}