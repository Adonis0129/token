// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
// Interfaces.
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

/**
 * @title FurMarket
 * @notice This is the NFT marketplace contract.
 */

/// @custom:security-contact security@furio.io
contract FurMarket is BaseContract, ERC721Holder
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
    }

    /**
     * External contracts.
     */
    IERC20 private _paymentToken;

    /**
     * Listings.
     */
    uint256 private _listingIdTracker;
    struct Listing {
        uint256 start;
        address token;
        uint256 id;
        uint256 price;
        uint256 offer;
        address offerAddress;
        address owner;
    }
    mapping(uint256 => Listing) _listings;

    /**
     * Events.
     */
    event ListingCreated(Listing);
    event ListingCancelled(Listing);
    event NftPurchased(Listing);
    event OfferPlaced(Listing);
    event OfferAccepted(Listing);
    event OfferRejected(Listing);

    /**
     * List NFT.
     * @param tokenAddress_ The address of the NFT contract.
     * @param tokenId_ The ID of the NFT.
     * @param price_ The price of the NFT.
     */
    function listNft(address tokenAddress_, uint256 tokenId_, uint256 price_) external whenNotPaused
    {
        IERC721 _token_ = IERC721(tokenAddress_);
        require(_token_.supportsInterface(type(IERC721).interfaceId), "Token must be ERC721");
        _transferERC721(tokenAddress_, tokenId_, msg.sender, address(this));
        _listingIdTracker++;
        _listings[_listingIdTracker].start = block.timestamp;
        _listings[_listingIdTracker].token = tokenAddress_;
        _listings[_listingIdTracker].id = tokenId_;
        _listings[_listingIdTracker].price = price_;
        _listings[_listingIdTracker].owner = msg.sender;
        emit ListingCreated(_listings[_listingIdTracker]);
    }

    /**
     * Cancel listing.
     * @param listingId_ The ID of the listing.
     */
    function cancelListing(uint256 listingId_) external whenNotPaused
    {
        require(_listings[listingId_].start > 0, "Listing does not exist");
        require(_listings[listingId_].owner == msg.sender, "Only the listing owner can cancel the listing");
        _transferERC721(_listings[listingId_].token, _listings[listingId_].id, address(this), msg.sender);
        emit ListingCancelled(_listings[listingId_]);
        _deleteListing(listingId_);
    }

    /**
     * Buy NFT.
     * @param listingId_ The ID of the listing.
     */
    function buyNft(uint256 listingId_) external whenNotPaused
    {
        require(_listings[listingId_].start > 0, "Listing does not exist");
        require(_paymentToken.transferFrom(msg.sender, _listings[listingId_].owner, _listings[listingId_].price), "Payment failed");
        _transferERC721(_listings[listingId_].token, _listings[listingId_].id, address(this), msg.sender);
        emit NftPurchased(_listings[listingId_]);
        _deleteListing(listingId_);
    }

    /**
     * Make offer.
     * @param listingId_ The ID of the listing.
     * @param offer_ The offer amount.
     */
    function makeOffer(uint256 listingId_, uint256 offer_) external whenNotPaused
    {
        require(_listings[listingId_].start > 0, "Listing does not exist");
        require(offer_ > _listings[listingId_].offer, "Offer must be higher than the highest offer");
        require(_paymentToken.transferFrom(msg.sender, address(this), offer_), "Payment failed");
        _listings[listingId_].offer = offer_;
        _listings[listingId_].offerAddress = msg.sender;
        emit OfferPlaced(_listings[listingId_]);
    }

    /**
     * Accept offer.
     * @param listingId_ The ID of the listing.
     */
    function acceptOffer(uint256 listingId_) external whenNotPaused
    {
        require(_listings[listingId_].start > 0, "Listing does not exist");
        require(_listings[listingId_].owner == msg.sender, "Only the listing owner can accept the offer");
        require(_paymentToken.transfer(_listings[listingId_].owner, _listings[listingId_].offer), "Payment failed");
        _transferERC721(_listings[listingId_].token, _listings[listingId_].id, address(this), _listings[listingId_].offerAddress);
        emit OfferAccepted(_listings[listingId_]);
        emit NftPurchased(_listings[listingId_]);
        _deleteListing(listingId_);
    }

    /**
     * Reject offer.
     * @param listingId_ The ID of the listing.
     */
    function rejectOffer(uint256 listingId_) external whenNotPaused
    {
        require(_listings[listingId_].start > 0, "Listing does not exist");
        require(_listings[listingId_].owner == msg.sender, "Only the listing owner can reject the offer");
        require(_paymentToken.transfer(_listings[listingId_].offerAddress, _listings[listingId_].offer), "Payment failed");
        emit OfferRejected(_listings[listingId_]);
        _listings[listingId_].offer = 0;
        _listings[listingId_].offerAddress = address(0);
    }

    /**
     * Get newest listings.
     * @param cursor_ The cursor.
     * @param limit_ The limit.
     */
    function getNewestListings(uint256 cursor_, uint256 limit_) external view returns (Listing[] memory)
    {
        Listing[] memory _listings_ = new Listing[](limit_);
        uint256 i;
        if(cursor_ == 0) cursor_ = _listingIdTracker;
        for(cursor_ = cursor_; cursor_ > cursor_; cursor_ --) {
            if (_listings[cursor_].start > 0) {
                _listings_[i] = _listings[cursor_];
                i++;
                if(i == limit_) cursor_ = 0;
            }
        }
        return _listings_;
    }

    /**
     * Get oldest listings.
     * @param cursor_ The cursor.
     * @param limit_ The limit.
     */
    function getOldestListings(uint256 cursor_, uint256 limit_) external view returns (Listing[] memory)
    {
        Listing[] memory _listings_ = new Listing[](limit_);
        uint256 i;
        if(cursor_ == 0) cursor_ = 1;
        for(cursor_ = cursor_; cursor_ <= _listingIdTracker; cursor_ ++) {
            if (_listings[cursor_].start > 0) {
                _listings_[i] = _listings[cursor_];
                i++;
                if(i == limit_) cursor_ = _listingIdTracker + 1;
            }
        }
        return _listings_;
    }

    /**
     * Delete listing.
     * @param listingId_ The ID of the listing.
     */
    function _deleteListing(uint256 listingId_) internal
    {
        uint256 start;
        address token;
        uint256 id;
        uint256 price;
        uint256 offer;
        address offerAddress;
        address owner;
        _listings[listingId_].start = 0;
        _listings[listingId_].token = address(0);
        _listings[listingId_].id = 0;
        _listings[listingId_].price = 0;
        _listings[listingId_].offer = 0;
        _listings[listingId_].offerAddress = address(0);
        _listings[listingId_].owner = address(0);
    }

    /**
     * Transfer ERC721.
     * @param tokenAddress_ The address of the token.
     * @param tokenId_ The ID of the token.
     * @param from_ The address of the sender.
     * @param to_ The address of the receiver.
     */
    function _transferERC721(address tokenAddress_, uint256 tokenId_, address from_, address to_) internal
    {
        IERC721 _token_ = IERC721(tokenAddress_);
        _token_.safeTransferFrom(from_, to_, tokenId_);
        require(_token_.ownerOf(tokenId_) == to_, "Token transfer failed");
    }
}
