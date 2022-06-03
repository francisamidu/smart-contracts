// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Azuki is Ownable, ERC721A, ReentrancyGuard {
  // Some immutable variable
  uint256 public immutable maxPerAddressDuringMint;
  uint256 public immutable amountForDevs;
  uint256 public immutable amountForAuctionAndDev;

  // Configuration of sale
  struct SaleConfig {
    uint32 auctionSaleStartTime;
    uint32 publicSaleStartTime;
    uint64 mintlistPrice;
    uint64 publicPrice;
    uint32 publicSaleKey;
  }

  SaleConfig public saleConfig;

  // Use mapping(address => uint256) to record the minting balance of every whitelist
  mapping(address => uint256) public allowlist;

  constructor(
    uint256 maxBatchSize_, // the explanation is on Medium
    uint256 collectionSize_, // the max supply of the NFT
    uint256 amountForAuctionAndDev_,
    uint256 amountForDevs_
  ) ERC721A("Azuki", "AZUKI", maxBatchSize_, collectionSize_) {
    maxPerAddressDuringMint = maxBatchSize_;
    amountForAuctionAndDev = amountForAuctionAndDev_;
    amountForDevs = amountForDevs_;
    require(
      amountForAuctionAndDev_ <= collectionSize_,
      "larger collection size needed"
    );
  }

  // Before calling mint function, check if the caller is the user rather than other contracts.
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  // The mint function used for auction
  function auctionMint(uint256 quantity) external payable callerIsUser {
    uint256 _saleStartTime = uint256(saleConfig.auctionSaleStartTime);
    // It can mint when the auction begins.
    require(
      _saleStartTime != 0 && block.timestamp >= _saleStartTime,
      "sale has not started yet"
    );
    // The sum of the minted amount and the quantity of caller inputs needs to be lower than the supply for auction and dev.
    require(
      totalSupply() + quantity <= amountForAuctionAndDev,
      "not enough remaining reserved for auction to support desired mint amount"
    );
    // The sum of the quantity caller inputs and the balance of NFT in the wallet should be lower than the max balance for every address during mint.
    require(
      numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
      "can not mint this many"
    );
    // Get the minting cost. But why its argument is `_saleStartTime` instead of the timestamp of calling the function?
    uint256 totalCost = getAuctionPrice(_saleStartTime) * quantity;
    // Use the ERC721A function `_safeMint`
    _safeMint(msg.sender, quantity);
    // Return the money if it's extra.
    refundIfOver(totalCost);
  }

  // The mint function for the whitelisted
  function allowlistMint() external payable callerIsUser {
    uint256 price = uint256(saleConfig.mintlistPrice);
    // Check if the mint for whitelists is begins.
    require(price != 0, "allowlist sale has not begun yet");
    require(allowlist[msg.sender] > 0, "not eligible for allowlist mint");
    // `totalSupply()` returns the length of the minted tokens
    require(totalSupply() + 1 <= collectionSize, "reached max supply");
    // Before caller call `_safeMint()`, it minus one in the amount of this whitelist can mint
    allowlist[msg.sender]--;
    // It mints one NFT everytime.
    _safeMint(msg.sender, 1);
    refundIfOver(price);
  }

  // The mint function for the public sale
  function publicSaleMint(uint256 quantity, uint256 callerPublicSaleKey)
    external
    payable
    callerIsUser
  {
    SaleConfig memory config = saleConfig;
    uint256 publicSaleKey = uint256(config.publicSaleKey);
    uint256 publicPrice = uint256(config.publicPrice);
    uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);
    // Need the correct key for the public sale
    require(
      publicSaleKey == callerPublicSaleKey,
      "called with incorrect public sale key"
    );

    // Check if the public sale starts
    require(
      isPublicSaleOn(publicPrice, publicSaleKey, publicSaleStartTime),
      "public sale has not begun yet"
    );
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(
      numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
      "can not mint this many"
    );
    _safeMint(msg.sender, quantity);
    refundIfOver(publicPrice * quantity);
  }

  // The function of returning the excess money
  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  // Anyone can check if the public sale starts
  function isPublicSaleOn(
    uint256 publicPriceWei,
    uint256 publicSaleKey,
    uint256 publicSaleStartTime
  ) public view returns (bool) {
    return
      publicPriceWei != 0 &&
      publicSaleKey != 0 &&
      block.timestamp >= publicSaleStartTime;
  }

  // Some configuration of the auction
  // Dutch auction starts at some high price and reduces the price with time passing by
  uint256 public constant AUCTION_START_PRICE = 1 ether;
  uint256 public constant AUCTION_END_PRICE = 0.15 ether;
  uint256 public constant AUCTION_PRICE_CURVE_LENGTH = 340 minutes;
  uint256 public constant AUCTION_DROP_INTERVAL = 20 minutes;
  uint256 public constant AUCTION_DROP_PER_STEP =
    (AUCTION_START_PRICE - AUCTION_END_PRICE) /
      (AUCTION_PRICE_CURVE_LENGTH / AUCTION_DROP_INTERVAL); //the reducing extent of every step

  // Anyone can get the so-far price of the auction
  function getAuctionPrice(uint256 _saleStartTime)
    public
    view
    returns (uint256)
  {
    if (block.timestamp < _saleStartTime) {
      return AUCTION_START_PRICE;
    }
    if (block.timestamp - _saleStartTime >= AUCTION_PRICE_CURVE_LENGTH) {
      return AUCTION_END_PRICE;
    } else {
      uint256 steps = (block.timestamp - _saleStartTime) /
        AUCTION_DROP_INTERVAL;
      return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
    }
  }

  // End the auction and setup some sale information about the price for `allowlist` and the public sale
  function endAuctionAndSetupNonAuctionSaleInfo(
    uint64 mintlistPriceWei,
    uint64 publicPriceWei,
    uint32 publicSaleStartTime
  ) external onlyOwner {
    saleConfig = SaleConfig(
      0,
      publicSaleStartTime,
      mintlistPriceWei,
      publicPriceWei,
      saleConfig.publicSaleKey
    );
  }

  // Decide when the auction starts
  function setAuctionSaleStartTime(uint32 timestamp) external onlyOwner {
    saleConfig.auctionSaleStartTime = timestamp;
  }

  // Set the key for the public sale
  function setPublicSaleKey(uint32 key) external onlyOwner {
    saleConfig.publicSaleKey = key;
  }

  // Set the whitelisted address and the amount they can mint
  function seedAllowlist(address[] memory addresses, uint256[] memory numSlots)
    external
    onlyOwner
  {
    require(
      addresses.length == numSlots.length,
      "addresses does not match numSlots length"
    );
    for (uint256 i = 0; i < addresses.length; i++) {
      allowlist[addresses[i]] = numSlots[i];
    }
  }

  // Free mint
  function devMint(uint256 quantity) external onlyOwner {
    // The sum of the minted amount and the input needs to be lower than amount for dev.
    require(
      totalSupply() + quantity <= amountForDevs,
      "too many already minted before dev mint"
    );
    // The input has to be a positive multiply of the `maxBatchSize`
    require(
      quantity % maxBatchSize == 0,
      "can only mint a multiple of the maxBatchSize"
    );
    // The logic of reducing the minting gas
    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }

  // // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  // withdraw the money in NFT contract to the owner address
  // use `nonReentrant` to protect from the reentrancy attack
  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  // For the logic of ERC721A, explicitly set `owners` to eliminate loops in future calls of `ownerOf()`.
  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  // Check how many NFT this address owns
  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  // It will return who owns this token and the timestamp he or she owns it.
  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
}
}