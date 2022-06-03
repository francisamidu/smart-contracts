// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RightsNFT is ERC721URIStorage, ReentrancyGuard  {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;

    struct Token { // NFT Right
        uint256 tokenId; // NFT right Id eg: 1
        string itemName; // NFT item name eg: Wedding Collection
        string rightName; // NFT right/support eg: Post production support
        string rightDescription; // NFT right description eg: This is the post-production right
        address owner; // NFT current owner (Will belong to the minter then can be transfered after purchase)
        uint256 price; // NFT price eg: 1000 crux tokens
        uint256 createdAt; // Date metadata
    }

    event TokenMinted(uint256 id, uint256 price,uint256 timestamp );

    event TokenBought(uint256 id, address newOwner);

    mapping (uint256=>Token) public idToTokenItem;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC721 (_tokenName, _tokenSymbol) {}

    function _baseURI() internal pure override returns (string memory baseURI) {
        return "https://gateway.ipfs.io/ipfs/";
    }   

    function mint(        
        string memory _tokenURI,
        string memory _itemName,
        string memory _right,
        string memory _rightDescription,
        uint256 _price,
        uint256 _createdAt
    ) public {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        idToTokenItem[tokenId].tokenId = tokenId;
        idToTokenItem[tokenId].itemName = _itemName;
        idToTokenItem[tokenId].owner = msg.sender;
        idToTokenItem[tokenId].rightName = _right;
        idToTokenItem[tokenId].rightDescription = _rightDescription;
        idToTokenItem[tokenId].createdAt = _createdAt;
        idToTokenItem[tokenId].price = _price;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        emit TokenMinted(tokenId, idToTokenItem[tokenId].price, _createdAt);
    }

    function transferNFT(address to, uint256 tokenId) internal {        
        safeTransferFrom(msg.sender,to,tokenId);
    }

    function buyRight(
       uint256 _tokenId,
       address buyer
    ) public payable {
        Token storage token = idToTokenItem[_tokenId];
        idToTokenItem[_tokenId].owner = buyer;
        require(token.owner != address(0), "Sorry right doesnt exist");
        require(msg.value >= token.price, "Not enough funds to make purchase");
        transferNFT(buyer, _tokenId);
        emit TokenBought(_tokenId, buyer);
    }

    // function transferOwnership(address _newOwner) public override {
    //   uint256 totalItemCount = _tokenIds.current();
      
    //   for(uint i =0; i < totalItemCount; i++){
    //       if(idToTokenItem[i + 1].owner == msg.sender){
    //         uint currentId = idToTokenItem[i + 1].tokenId;
    //         idToTokenItem[currentId].owner = _newOwner;
    //         _transfer(msg.sender,_newOwner,currentId);
    //       }
    //   }
    // }

    function _beforeTokenTransfer(address from, address to, uint256 _tokenId) 
    internal override(ERC721){
        super._beforeTokenTransfer(from, to, _tokenId);
    } 

    // function withdraw() public nonReentrant {
    //     (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    //     require(os);    
    // }
}
