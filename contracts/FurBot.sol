// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
// Interfaces
import "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @title FurBot
 * @notice This is the NFT contract for FurBot.
 */

/// @custom:security-contact security@furio.io
contract FurBot is BaseContract, ERC721Upgradeable
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
        __ERC721_init("FurBot", "$FURBOT");
    }

    /**
     * Global stats.
     */
    uint256 public totalSupply;
    uint256 public totalInvestment;
    uint256 public totalDividends;

    /**
     * External contracts.
     */
    IERC20 public paymentToken;

    /**
     * Generations.
     */
    uint256 private _generationIdTracker;
    mapping(uint256 => uint256) private _generationMaxSupply;
    mapping(uint256 => uint256) private _generationTotalSupply;
    mapping(uint256 => uint256) private _generationInvestment;
    mapping(uint256 => uint256) private _generationDividends;
    mapping(uint256 => string) private _generationImageUri;

    /**
     * Sales.
     */
    uint256 private _saleIdTracker;
    mapping(uint256 => uint256) private _saleGenerationId;
    mapping(uint256 => uint256) private _salePrice;
    mapping(uint256 => uint256) private _saleStart;
    mapping(uint256 => uint256) private _saleEnd;

    /**
     * Tokens.
     */
    uint256 private _tokenIdTracker;
    mapping(uint256 => uint256) private _tokenGenerationId;
    mapping(uint256 => uint256) private _tokenInvestment;
    mapping(uint256 => uint256) private _tokenDividendsClaimed;

    /**
     * Events.
     */
    event GenerationCreated(uint256 indexed id_);
    event SaleCreated(uint256 indexed id_);
    event TokenPurchased(uint256 indexed id_);
    event DividendsClaimed(address indexed owner_, uint256 amount_);

    /**
     * Setup.
     */
    function setup() external
    {
        paymentToken = IERC20(addressBook.get("payment"));
    }

    /**
     * Token of owner by index.
     * @param owner_ The owner address.
     * @param index_ The index of the token.
     */
    function tokenOfOwnerByIndex(address owner_, uint256 index_) public view returns (uint256)
    {
        require(balanceOf(owner_) > index_, "Index out of bounds");
        for(uint256 i = 1; i <= totalSupply; i++) {
            if(ownerOf(i) == owner_) {
                if(index_ == 0) {
                    return i;
                }
                index_--;
            }
        }
    }

    /**
     * Get active sale.
     * @return uint256 The sale ID.
     */
    function getActiveSale() public view returns(uint256)
    {
        for(i = 1; i <= _saleIdTracker; i++) {
            if(_saleStart[i] <= block.timestamp && _saleEnd[i] >= block.timestamp) {
                return i;
            }
        }
        return 0;
    }

    /**
     * Get next sale.
     * @return uint256 The sale ID.
     */
    function getNextSale() public view returns(uint256)
    {
        for(i = 1; i <= _saleIdTracker; i++) {
            if(_saleStart[i] > block.timestamp) {
                return i;
            }
        }
        return 0;
    }

    /**
     * Get active sale price.
     * @return uint256 The price.
     */
    function getActiveSalePrice() public view returns(uint256)
    {
        return _salePrice[getActiveSale()];
    }

    /**
     * Get next sale price.
     * @return uint256 The price.
     */
    function getNextSalePrice() public view returns(uint256)
    {
        return _salePrice[getNextSale()];
    }

    /**
     * Buy.
     * @param amount_ The amount of tokens to buy.
     */
    function buy(uint256 amount_) external
    {
        uint256 _saleId_ = getActiveSale();
        require(_saleId_ > 0, "No active sale.");
        uint256 _generationId_ = _saleGenerationId[_saleId_];
        require(_generationTotalSupply[_generationId_] + amount_ <= _generationMaxSupply[_generationId_], "Max supply reached.");
        uint256 _investmentAmount_ = _salePrice[_saleId_] * amount_;
        require(paymentToken.transferFrom(msg.sender, address(this), _investmentAmount_), "Payment failed.");
        for(uint256 i = 1; i <= amount_; i++) {
            _tokenIdTracker++;
            totalSupply++;
            _generationTotalSupply[_generationId_]++;
            totalInvestment += _salePrice[_saleId_];
            _generationInvestment[_generationId_] += _salePrice[_saleId_];
            _tokenGenerationId[_tokenIdTracker] = _generationId_;
            _tokenInvestment[_tokenIdTracker] = _salePrice[_saleId_];
            _mint(msg.sender, _tokenIdTracker);
            emit TokenPurchased(_tokenIdTracker);
        }
    }

    /**
     * Available dividends by owner.
     * @return uint256 The available dividends.
     */
    function availableDividends() external view returns(uint256)
    {
        uint256 _dividends_;
        for(uint256 i = 1; i <= totalSupply; i++) {
            if(ownerOf(i) == msg.sender) {
                _dividends_ += availableDividendsByToken(i);
            }
        }
        return _dividends_;
    }

    /**
     * Available dividends by token.
     * @param tokenId_ The token ID.
     * @return uint256 The available dividends.
     */
    function availableDividendsByToken(uint256 tokenId_) public view returns(uint256)
    {
        uint256 _generationId_ = _tokenGenerationId[tokenId_];
        require(_generationId_ > 0, "Invalid token ID.");
        uint256 _dividendsPerShare_ = _generationDividends[_generationId_] / _generationTotalSupply[_generationId_];
        return _dividendsPerShare_ - _tokenDividendsClaimed[tokenId_];
    }

    /**
     * Claim dividends.
     */
    function claimDividends() external
    {
        require(balanceOf(msg.sender) > 0, "No tokens owned.");
        uint256 _dividends_;
        uint256 _totalDividends_;
        for(uint256 i = 1; i <= totalSupply; i++) {
            if(ownerOf(i) == owner_) {
                _dividends_ = availableDividendsByToken(i);
                _totalDividends_ += _dividends_;
                _tokenDividendsClaimed[i] += _dividends_;
            }
        }
        require(paymentToken.transfer(msg.sender, _totalDividends_), "Transfer failed.");
        emit DividendsClaimed(msg.sender, amount_);
    }

    /**
     * -------------------------------------------------------------------------
     * ADMIN FUNCTIONS.
     * -------------------------------------------------------------------------
     */

    /**
     * Create generation.
     * @param maxSupply_ The maximum supply of this generation.
     * @param imageUri_ The image URI for this generation.
     */
    function createGeneration(uint256 maxSupply_, string memory imageUri_) external onlyOwner
    {
        _generationIdTracker++;
        _generationMaxSupply[_generationIdTracker] = maxSupply_;
        _generationImageUri[_generationIdTracker] = imageUri_;
        emit GenerationCreated(_generationIdTracker);
    }

    /**
     * Create sale.
     * @param generationId_ The generation ID for this sale.
     * @param price_ The price for this sale.
     * @param start_ The start time for this sale.
     * @param end_ The end time for this sale.
     */
    function createSale(uint256 generationId_, uint256 price_, uint256 start_, uint256 end_) external onlyOwner
    {
        require(generationId_ > 0 && generationId_ <= _generationIdTracker, "Invalid generation ID.");
        require(start_ > block.timestamp, "Start time must be in the future.");
        if(_saleIdTracker > 0) {
            require(start_ > _saleEnd[_saleIdTracker], "Start time must be after the previous sale.");
        }
        require(end_ > start_, "End time must be after start time.");
        _saleGenerationId++;
        _saleGenerationId[_saleIdTracker] = generationId_;
        _salePrice[_saleIdTracker] = price_;
        _saleStart[_saleIdTracker] = start_;
        _saleEnd[_saleIdTracker] = end_;
        emit SaleCreated(_saleIdTracker);
    }
}
