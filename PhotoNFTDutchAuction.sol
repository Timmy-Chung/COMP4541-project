// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title PhotoNFTDutchAuction
 * @dev A contract that mints a single NFT and immediately starts a Dutch auction for it.
 */
contract PhotoNFTDutchAuction is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint256 public immutable nftIdToAuction;
    address payable public immutable seller;
    uint256 public immutable startingPrice;
    uint256 public immutable startAt;
    uint256 public immutable expiresAt;
    uint256 public immutable discountRate;
    bool public auctionEnded;

    event AuctionCreatedForNFT(
        uint256 indexed nftId,
        address indexed contractAddress,
        address indexed seller,
        uint256 startingPrice,
        uint256 discountRate,
        uint256 expiresAt,
        string tokenURI
    );

    event NFTSold(
        uint256 indexed nftId,
        address indexed buyer,
        uint256 pricePaid
    );

    event AuctionExpiredAndNFTReclaimed(
        uint256 indexed nftId,
        address indexed seller
    );

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _tokenURI,
        address payable _sellerAddress,
        uint256 _startingPrice,
        uint256 _discountRate,
        uint256 _auctionDuration
    ) ERC721(_tokenName, _tokenSymbol) {
        require(_sellerAddress != address(0), "Seller cannot be zero address");
        require(_startingPrice > 0, "Starting price must be > 0");
        require(_discountRate > 0, "Discount rate must be > 0");
        require(_auctionDuration > 0, "Auction duration must be > 0");

        uint256 durationInSeconds = _auctionDuration;
        require(
            _startingPrice >= _discountRate * durationInSeconds,
            "Starting price too low"
        );

        seller = _sellerAddress;
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        nftIdToAuction = newItemId;

        _safeMint(address(this), newItemId);
        _setTokenURI(newItemId, _tokenURI);

        startingPrice = _startingPrice;
        discountRate = _discountRate;
        startAt = block.timestamp;
        expiresAt = block.timestamp + durationInSeconds;
        auctionEnded = false;

        emit AuctionCreatedForNFT(
            newItemId,
            address(this),
            seller,
            _startingPrice,
            _discountRate,
            expiresAt,
            _tokenURI
        );
    }

    function getCurrentPrice() public view returns (uint256) {
        if (auctionEnded) {
            uint256 totalPossibleDiscount = discountRate * (expiresAt - startAt);
            if (totalPossibleDiscount >= startingPrice) return 0;
            return startingPrice - totalPossibleDiscount;
        }
        if (block.timestamp >= expiresAt) {
            uint256 totalPossibleDiscount = discountRate * (expiresAt - startAt);
            if (totalPossibleDiscount >= startingPrice) return 0;
            return startingPrice - totalPossibleDiscount;
        }

        uint256 timeElapsed = block.timestamp - startAt;
        uint256 currentDiscount = discountRate * timeElapsed;

        if (currentDiscount >= startingPrice) {
            return 0;
        }
        return startingPrice - currentDiscount;
    }

    function buyNFT() external payable {
        require(!auctionEnded, "Auction has already ended");
        require(block.timestamp < expiresAt, "Auction has expired");

        uint256 currentPrice = getCurrentPrice();
        require(msg.value >= currentPrice, "Not enough Ether");

        auctionEnded = true;
        _transfer(address(this), msg.sender, nftIdToAuction);
        payable(seller).transfer(currentPrice);

        if (msg.value > currentPrice) {
            payable(msg.sender).transfer(msg.value - currentPrice);
        }
        emit NFTSold(nftIdToAuction, msg.sender, currentPrice);
    }

    function reclaimUnsoldNFT() external {
        require(msg.sender == seller, "Only seller");
        require(block.timestamp >= expiresAt, "Auction not expired");
        require(!auctionEnded, "Auction ended");

        auctionEnded = true;
        _transfer(address(this), seller, nftIdToAuction);
        emit AuctionExpiredAndNFTReclaimed(nftIdToAuction, seller);
    }

    // --- ERC721 Overrides ---

    // _update is defined in ERC721 and not overridden by ERC721URIStorage.
    // So, we only need to specify ERC721 in the override.
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721) // Corrected: Only ERC721 as ERC721URIStorage doesn't override it
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    // _increaseBalance is defined in ERC721 and not overridden by ERC721URIStorage.
    // So, we only need to specify ERC721 in the override.
    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721) // Corrected: Only ERC721 as ERC721URIStorage doesn't override it
    {
        super._increaseBalance(account, value);
    }

    // tokenURI is defined in ERC721 and overridden by ERC721URIStorage.
    // Our contract overrides the version from ERC721URIStorage.
    // The call to super.tokenURI() will invoke ERC721URIStorage.tokenURI(),
    // which already includes the necessary existence check (_requireMinted).
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage) // Overriding both as ERC721URIStorage overrides ERC721's
        returns (string memory)
    {
        // REMOVED: require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // The check is handled by super.tokenURI() which calls ERC721URIStorage.tokenURI()
        return super.tokenURI(tokenId);
    }

    // supportsInterface is defined in ERC721 and overridden by ERC721URIStorage.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage) // Overriding both
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}