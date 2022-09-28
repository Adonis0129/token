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
    mapping(uint256 => uint256) _listingStartTime;
    mapping(uint256 => address) _listingTokenAddress;
    mapping(uint256 => uint256) _listingTokenId;
    mapping(uint256 => uint256) _listingPrice;
    mapping(uint256 => uint256) _listingHighestOffer;
    mapping(uint256 => address) _listingHighestOfferAddress;
    mapping(uint256 => address) _listingOwnerAddress;

    struct Listing {
        uint256 id;
        uint256 startTime;
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
        uint256 highestOffer;
        address highestOfferAddress;
        address ownerAddress;
    }

    /**
     * Events.
     */
    event ListingCreated(uint256 indexed listingId, address tokenAddress, uint256 tokenId, uint256 price);
    event ListingCancelled(uint256 indexed listingId);
    event NftPurchased(uint256 indexed listingId, address tokenAddress, uint256 tokenId, address buyerAddress, uint256 price);
    event OfferPlaced(uint256 indexed listingId, address buyerAddress, uint256 price);
    event OfferAccepted(uint256 indexed listingId, address buyerAddress, uint256 price);
    event OfferRejected(uint256 indexed listingId, address buyerAddress, uint256 price);

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
        require(_token_.ownerOf(tokenId_) == address(this), "Token transfer failed");
        _listingIdTracker++;
        _listingStartTime[_listingIdTracker] = block.timestamp;
        _listingTokenAddress[_listingIdTracker] = tokenAddress_;
        _listingTokenId[_listingIdTracker] = tokenId_;
        _listingPrice[_listingIdTracker] = price_;
        emit ListingCreated(_listingIdTracker, tokenAddress_, tokenId_, price_);
    }

    /**
     * Cancel listing.
     * @param listingId_ The ID of the listing.
     */
    function cancelListing(uint256 listingId_) external whenNotPaused
    {
        require(_listingStartTime[listingId_] > 0, "Listing does not exist");
        require(_listingOwnerAddress[listingId_] == msg.sender, "Only the listing owner can cancel the listing");
        _transferERC721(_listingTokenAddress[listingId_], _listingTokenId[listingId_], address(this), msg.sender);
        emit ListingCancelled(listingId_);
        _deleteListing(listingId_);
    }

    /**
     * Buy NFT.
     * @param listingId_ The ID of the listing.
     */
    function buyNft(uint256 listingId_) external whenNotPaused
    {
        require(_listingStartTime[listingId_] > 0, "Listing does not exist");
        require(_paymentToken.transferFrom(msg.sender, _listingOwnerAddress[listingId_], _listingPrice[listingId_]), "Payment failed");
        _transferERC721(_listingTokenAddress[listingId_], _listingTokenId[listingId_], address(this), msg.sender);
        emit NftPurchased(listingId_, _listingTokenAddress[listingId_], _listingTokenId[listingId_], msg.sender, _listingPrice[listingId_]);
        _deleteListing(listingId_);
    }

    /**
     * Make offer.
     * @param listingId_ The ID of the listing.
     * @param offer_ The offer amount.
     */
    function makeOffer(uint256 listingId_, uint256 offer_) external whenNotPaused
    {
        require(_listingStartTime[listingId_] > 0, "Listing does not exist");
        require(offer_ > _listingHighestOffer[listingId_], "Offer must be higher than the highest offer");
        require(_paymentToken.transferFrom(msg.sender, address(this), offer_), "Payment failed");
        if (_listingHighestOffer[listingId_] > 0) {
            require(_paymentToken.transfer(_listingHighestOfferAddress[listingId_], _listingHighestOffer[listingId_]), "Payment failed");
        }
        _listingHighestOffer[listingId_] = offer_;
        _listingHighestOfferAddress[listingId_] = msg.sender;
        emit OfferPlaced(listingId_, msg.sender, offer_);
    }

    /**
     * Accept offer.
     * @param listingId_ The ID of the listing.
     */
    function acceptOffer(uint256 listingId_) external whenNotPaused
    {
        require(_listingStartTime[listingId_] > 0, "Listing does not exist");
        require(_listingOwnerAddress[listingId_] == msg.sender, "Only the listing owner can accept the offer");
        _transferERC721(_listingTokenAddress[listingId_], _listingTokenId[listingId_], address(this), _listingHighestOfferAddress[listingId_]);
        require(_paymentToken.transfer(_listingOwnerAddress[listingId_], _listingHighestOffer[listingId_]), "Payment failed");
        emit OfferAccepted(listingId_, _listingHighestOfferAddress[listingId_], _listingHighestOffer[listingId_]);
        emit NftPurchased(listingId_, _listingTokenAddress[listingId_], _listingTokenId[listingId_], _listingHighestOfferAddress[listingId_], _listingHighestOffer[listingId_]);
        _deleteListing(listingId_);
    }

    /**
     * Reject offer.
     * @param listingId_ The ID of the listing.
     */
    function rejectOffer(uint256 listingId_) external whenNotPaused
    {
        require(_listingStartTime[listingId_] > 0, "Listing does not exist");
        require(_listingOwnerAddress[listingId_] == msg.sender, "Only the listing owner can reject the offer");
        require(_paymentToken.transfer(_listingHighestOfferAddress[listingId_], _listingHighestOffer[listingId_]), "Payment failed");
        emit OfferRejected(listingId_, _listingHighestOfferAddress[listingId_], _listingHighestOffer[listingId_]);
        _listingHighestOffer[listingId_] = 0;
        _listingHighestOfferAddress[listingId_] = address(0);
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
            if (_listingStartTime[cursor_] > 0) {
                _listings_[i] = Listing({
                    id: cursor_,
                    startTime: _listingStartTime[cursor_],
                    tokenAddress: _listingTokenAddress[cursor_],
                    tokenId: _listingTokenId[cursor_],
                    price: _listingPrice[cursor_],
                    highestOffer: _listingHighestOffer[cursor_],
                    highestOfferAddress: _listingHighestOfferAddress[cursor_],
                    ownerAddress: _listingOwnerAddress[cursor_]
                });
                i++;
                if(i == limit_) cursor_ = 0;
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
        _listingStartTime[listingId_] = 0;
        _listingTokenAddress[listingId_] = address(0);
        _listingTokenId[listingId_] = 0;
        _listingPrice[listingId_] = 0;
        _listingHighestOffer[listingId_] = 0;
        _listingHighestOfferAddress[listingId_] = address(0);
        _listingOwnerAddress[listingId_] = address(0);
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
