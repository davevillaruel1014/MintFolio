// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";

contract CryptoDevs is ReentrancyGuard, ERC721URIStorage, Ownable {
    
    using SafeMath for uint256;

    uint256 public tokenCounter;

    string public CRYPTODEVS_PROVENANCE = "";

    uint256 public constant MAX_TOKENS = 10;

    mapping(uint256 => bool) public TokenAlive;

    mapping(uint256 => address) public TokenToOwner;

    
    // uint256 public constant MAX_TOKENS_PER_PURCHASE = 20;

    uint256 private price = 25000000000000000; // 0.025 Ether
    string public baseURI = "";

    bool public isSaleActive = true;

    constructor() 
    ERC721("CryptoDevs", "DEVS") {
        tokenCounter = 1;
    }

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        CRYPTODEVS_PROVENANCE = _provenanceHash;
    }
        
    // function reserveTokens(address _to, uint256 _reserveAmount) public onlyOwner {        
    //     uint supply = totalSupply();
    //     for (uint i = 0; i < _reserveAmount; i++) {
    //         _safeMint(_to, supply + i);
    //     }
    // }
    
    function mint() public payable {
        require(isSaleActive, "Sale is not active" );
        require(tokenCounter < MAX_TOKENS + 1, "Exceeds maximum tokens available for purchase");
        require(msg.value >= price, "token value sent is not correct");
        uint256 tokenId = tokenCounter;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, formatTokenURI(tokenId));
        TokenToOwner[tokenId] = msg.sender;
        TokenAlive[tokenId] = true;
        tokenCounter = tokenCounter + 1;
    }

    function burn(uint256 tokenId) public {
        require(TokenToOwner[tokenId] == msg.sender, "You are not the owner of this NFT");
        require(TokenAlive[tokenId] == true, "This NFT is already burned!");
        _burn(tokenId);
        TokenAlive[tokenId] = false;
    }

    function formatTokenURI(uint256 tokenId) public view returns (string memory) {
        string memory uri = "";

        // baseuri = "ipfs://QmXsX1u1oevaBb3ANvRduo9sfcnGQiASshPNUSyvvuMJ7Z/metadata/"
        // QmXsX1u1oevaBb3ANvRduo9sfcnGQiASshPNUSyvvuMJ7Z
    
        for(uint256 i = 0; i < 64-getNumberLength(tokenId) ;i++){
            uri = string(abi.encodePacked(uri, "0"));
        }

        return string(
            abi.encodePacked(baseURI, uri, Strings.toString(tokenId), ".json")
            );
    }

    function getNumberLength(uint256 num) public pure returns (uint256){
        uint256 length = 0;
        while (num != 0) { num >>= 8; length++; }
        return length;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function flipSaleStatus() public onlyOwner {
        isSaleActive = !isSaleActive;
    }
     
    function setPrice(uint256 _newPrice) public onlyOwner() {
        price = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return price;
    }

    function withdraw() public payable onlyOwner {
       payable(owner()).transfer(address(this).balance);
    }
    
    // function tokensByOwner(address _owner) external view returns(uint256[] memory ) {
    //     uint256 tokenCount = balanceOf(_owner);
    //     if (tokenCount == 0) {
    //         return new uint256[](0);
    //     } else {
    //         uint256[] memory result = new uint256[](tokenCount);
    //         uint256 index;
    //         for (index = 0; index < tokenCount; index++) {
    //             result[index] = tokenOfOwnerByIndex(_owner, index);
    //         }
    //         return result;
    //     }
    // }
}