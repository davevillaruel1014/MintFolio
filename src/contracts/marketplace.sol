// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "base64-sol/base64.sol";

contract marketplace is ReentrancyGuard, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    mapping(bytes32 => address) public requestIdToSender;
    mapping(uint256 => uint256) public tokenIdToRandomNumber;
    mapping(bytes32 => uint256) public requestIdToTokenId;

    uint256 public tokenCounter;
    uint256 public tokenPrice;
    uint256 public maxNumberOfPaths;
    uint256 public maxNumberOfPathCommands;
    uint256 public size;
    string[] public pathCommands;
    string[] public colors;
    
    address public ownerContract;
     
     constructor() 
     ERC721("RandomSVG", "rsNFT")
        {
        tokenCounter = 0;
        tokenPrice = 10000000000000; // 0.00001 token
        maxNumberOfPaths = 10;
        maxNumberOfPathCommands = 5;
        size = 500;
        pathCommands = ["M", "L"];
        colors = ["red", "blue", "green", "black"];

        ownerContract = msg.sender;
        }   
     
     struct MarketItem {
         uint itemId;
         address nftContract;
         uint256 tokenId;
         address payable seller;
         address payable owner;
         uint256 price;
         bool sold;
     }
     
     mapping(uint256 => MarketItem) private idToMarketItem;
     
     event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
     );

     event mintedItem (
        address indexed nftContract,
        uint256 indexed tokenId,
        address owner,
        uint256 price
     );
     
     event MarketItemSold (
         uint indexed itemId,
         address owner
         );
     
    
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
        ) public payable nonReentrant {
            require(price > 0, "Price must be greater than 0");
            
            _itemIds.increment();
            uint256 itemId = _itemIds.current();
  
            idToMarketItem[itemId] =  MarketItem(
                itemId,
                nftContract,
                tokenId,
                payable(msg.sender),
                payable(address(0)),
                price,
                false
            );
            
            IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
                
            emit MarketItemCreated(
                itemId,
                nftContract,
                tokenId,
                msg.sender,
                address(0),
                price,
                false
            );
        }
        
    function createMarketSale(
        address nftContract,
        uint256 itemId
        ) public payable nonReentrant {
            uint price = idToMarketItem[itemId].price;
            uint tokenId = idToMarketItem[itemId].tokenId;
            bool sold = idToMarketItem[itemId].sold;
            require(msg.value == price, "Please submit the asking price in order to complete the purchase");
            require(sold != true, "This Sale has alredy finnished");
            emit MarketItemSold(
                itemId,
                msg.sender
                );

            idToMarketItem[itemId].seller.transfer(msg.value);
            IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
            idToMarketItem[itemId].owner = payable(msg.sender);
            _itemsSold.increment();
            idToMarketItem[itemId].sold = true;
        }
        
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(0)) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // ///////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////
    // Minting NFT contract 

    function withdraw() public payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function create() public payable{
        require(msg.value >= tokenPrice, "Need to send more tokens to mint!");
        uint256 tokenId = tokenCounter; 
        tokenCounter = tokenCounter + 1;
        _safeMint(msg.sender, tokenId);

        uint256 randomNumber = uint256(keccak256(abi.encode(tokenId)));
        string memory svg = generateSVG(randomNumber);
        string memory imageURI = svgToImageURI(svg);
        _setTokenURI(tokenId, formatTokenURI(imageURI));

        emit mintedItem(
                address(this),
                tokenId,
                msg.sender,
                tokenPrice
        );
    }

    function generateSVG(uint256 _randomness) public view returns (string memory finalSvg) {
        // We will only use the path element, with stroke and d elements
        uint256 numberOfPaths = (_randomness % maxNumberOfPaths) + 1;
        finalSvg = string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' height='", uint2str(size), "' width='", uint2str(size), "'>"));
        for(uint i = 0; i < numberOfPaths; i++) {
            // we get a new random number for each path
            string memory pathSvg = generatePath(uint256(keccak256(abi.encode(_randomness, i))));
            finalSvg = string(abi.encodePacked(finalSvg, pathSvg));
        }
        finalSvg = string(abi.encodePacked(finalSvg, "</svg>"));
    }

    function generatePath(uint256 _randomness) public view returns(string memory pathSvg) {
        uint256 numberOfPathCommands = (_randomness % maxNumberOfPathCommands) + 1;
        pathSvg = "<path d='";
        for(uint i = 0; i < numberOfPathCommands; i++) {
            string memory pathCommand = generatePathCommand(uint256(keccak256(abi.encode(_randomness, size + i))));
            pathSvg = string(abi.encodePacked(pathSvg, pathCommand));
        }
        string memory color = colors[_randomness % colors.length];
        pathSvg = string(abi.encodePacked(pathSvg, "' fill='transparent' stroke='", color,"'/>"));
    }

    function generatePathCommand(uint256 _randomness) public view returns(string memory pathCommand) {
        pathCommand = pathCommands[_randomness % pathCommands.length];
        uint256 parameterOne = uint256(keccak256(abi.encode(_randomness, size * 2))) % size;
        uint256 parameterTwo = uint256(keccak256(abi.encode(_randomness, size * 2 + 1))) % size;
        pathCommand = string(abi.encodePacked(pathCommand, " ", uint2str(parameterOne), " ", uint2str(parameterTwo)));
    }
    
    // From: https://stackoverflow.com/a/65707309/11969592
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }




    // You could also just upload the raw SVG and have solildity convert it!
    function svgToImageURI(string memory svg) public pure returns (string memory) {
        // example:
        // <svg width='500' height='500' viewBox='0 0 285 350' fill='none' xmlns='http://www.w3.org/2000/svg'><path fill='black' d='M150,0,L75,200,L225,200,Z'></path></svg>
        // data:image/svg+xml;base64,PHN2ZyB3aWR0aD0nNTAwJyBoZWlnaHQ9JzUwMCcgdmlld0JveD0nMCAwIDI4NSAzNTAnIGZpbGw9J25vbmUnIHhtbG5zPSdodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2Zyc+PHBhdGggZmlsbD0nYmxhY2snIGQ9J00xNTAsMCxMNzUsMjAwLEwyMjUsMjAwLFonPjwvcGF0aD48L3N2Zz4=
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
        return string(abi.encodePacked(baseURL,svgBase64Encoded));
    }

    function formatTokenURI(string memory imageURI) public pure returns (string memory) {
        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                "SVG NFT", // You can add whatever name here
                                '", "description":"An NFT based on SVG!", "attributes":"", "image":"',imageURI,'"}'
                            )
                        )
                    )
                )
            );
    }

    // remove later:
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
      
}

/// Thanks for inspiration: https://github.com/dabit3/polygon-ethereum-nextjs-marketplace/


// furter steps
// deploy new contract
// add in sync for mintedItem event, and listitemevent
// chainlink vrf using triggers or cloud functionlality 