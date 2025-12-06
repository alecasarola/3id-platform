// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DataNFT is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct DataBundle {
        string dataHash;
        string encryptedCID;
        address ownerDID;
        uint256 timestamp;
        bool isActive;
    }

    mapping(uint256 => DataBundle) public dataBundles;

    event DataBundleMinted(
        uint256 indexed tokenId,
        address indexed owner,
        string dataHash,
        string encryptedCID,
        uint256 timestamp
    );

    event DataBundleTransferred(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        uint256 timestamp
    );

    constructor() ERC721("DID Data Bundle", "DDB") Ownable(msg.sender) {}

    function mintDataBundle(
        address to,
        string memory tokenURI,
        string memory dataHash,
        string memory encryptedCID
    ) public onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);

        dataBundles[tokenId] = DataBundle({
            dataHash: dataHash,
            encryptedCID: encryptedCID,
            ownerDID: to,
            timestamp: block.timestamp,
            isActive: true
        });

        emit DataBundleMinted(
            tokenId,
            to,
            dataHash,
            encryptedCID,
            block.timestamp
        );

        return tokenId;
    }

    function verifyDataIntegrity(
        uint256 tokenId,
        string memory dataHash
    ) public view returns (bool) {
        require(_exists(tokenId), "Token does not exist");
        return keccak256(bytes(dataBundles[tokenId].dataHash)) == keccak256(bytes(dataHash));
    }

    function getDataBundle(uint256 tokenId) public view returns (DataBundle memory) {
        require(_exists(tokenId), "Token does not exist");
        return dataBundles[tokenId];
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}