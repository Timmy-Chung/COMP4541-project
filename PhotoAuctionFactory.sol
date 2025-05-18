// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./PhotoNFTDutchAuction.sol"; // Make sure PhotoNFTDutchAuction.sol is in the same directory or path is correct

/**
 * @title PhotoAuctionFactory
 * @dev A factory contract to deploy PhotoNFTDutchAuction contracts.
 * This provides a simple interface for users to create an NFT from a photo URI
 * and start a Dutch auction for it, similar to pump.fun's ease of use.
 */
contract PhotoAuctionFactory {
    event NewPhotoAuctionDeployed(
        address indexed auctionContractAddress,
        uint256 indexed nftId,
        address indexed seller,
        string tokenURI,
        uint256 startingPrice,
        uint256 auctionDuration
    );

    /**
     * @dev Deploys a new PhotoNFTDutchAuction contract.
     * This is the "additional function" that allows anyone to create an NFT (via URI)
     * and auction it.
     * @param _tokenName Name for the NFT collection (e.g., "My Awesome Photo Series").
     * @param _tokenSymbol Symbol for the NFT collection (e.g., "MAPS").
     * @param _tokenURI URI for the NFT's metadata (e.g., IPFS link to JSON describing the photo).
     * @param _startingPrice The initial price for the Dutch auction in wei.
     * @param _discountRate The rate (in wei per second) at which the price decreases.
     * @param _auctionDuration The duration of the auction in seconds.
     */
    function createPhotoNFTAndAuction(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _tokenURI,
        uint256 _startingPrice,
        uint256 _discountRate,
        uint256 _auctionDuration
    ) external returns (address auctionContractAddress) {
        // The caller of this function (msg.sender) becomes the seller of the NFT.
        PhotoNFTDutchAuction newAuctionContract = new PhotoNFTDutchAuction(
            _tokenName,
            _tokenSymbol,
            _tokenURI,
            payable(msg.sender), // The creator (msg.sender) is the seller
            _startingPrice,
            _discountRate,
            _auctionDuration
        );

        auctionContractAddress = address(newAuctionContract);

        emit NewPhotoAuctionDeployed(
            auctionContractAddress,
            newAuctionContract.nftIdToAuction(), // The NFT ID within the new contract (will be 1)
            msg.sender, // Seller
            _tokenURI,
            _startingPrice,
            _auctionDuration
        );

        return auctionContractAddress;
    }
}