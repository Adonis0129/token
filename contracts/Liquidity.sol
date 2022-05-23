// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
// Interfaces.
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/**
 * @title Furio Liquidity
 * @author Steve Harmeyer
 * @notice This is the ERC20 contract for $FUR.
 */

/// @custom:security-contact security@furio.io
contract FurioToken is BaseContract
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
        _openingPrice = 2500000000000000000;
        _poolCreated = false;
    }

    /**
     * Opening price.
     * @dev The opening price for _token.
     */
    uint256 private _openingPrice;

    /**
     * Payment token.
     * @dev The payment token (USDC).
     */
    IERC20 private _payment;

    /**
     * Token.
     * @dev The token ($FUR).
     */
    IERC20 private _token;

    /**
     * Router.
     * @dev The Uniswap router.
     */
    IUniswapV2Router02 private _router;

    /**
     * Dev wallet.
     * @dev The dev wallet address.
     */
    address private _devWallet;

    /**
     * Pool created.
     * @dev True if liquidity pool has already been created.
     */
    bool private _poolCreated;

    /**
     * Set opening price.
     * @param price_ The new opening price.
     * @dev Sets the opening price.
     */
    function setOpeningPrice(uint256 price_) external onlyOwner
    {
        require(!_poolCreated, "Liquidity pool has already been created.");
        _openingPrice = price_;
    }

    /**
     * Set payment.
     * @param address_ Address for payment token.
     * @dev Sets the payment token.
     */
    function setPayment(address address_) external onlyOwner
    {
        _payment = IERC20(address_);
    }

    /**
     * Set token.
     * @param address_ Address for the token.
     * @dev Sets the token.
     */
    function setToken(address address_) external onlyOwner
    {
        _token = IERC20(address_);
    }

    /**
     * Set router.
     * @param address_ Address for the router.
     * @dev Sets the router.
     */
    function setRouter(address address_) external onlyOwner
    {
        _router = IUniswapV2Router02(address_);
    }

    /**
     * Set dev wallet.
     * @param address_ Address for the dev wallet.
     * @dev Sets the dev wallet address.
     */
    function setDevWallet(address address_) external onlyOwner
    {
        _devWallet = address_;
    }

    /**
     * Create liquidity.
     * @dev Creates a liquidity pool with _payment and _token.
     */
    function createLiquidity() external onlyOwner
    {
        require(address(_router) != address(0), "Router not set");
        require(_devWallet != address(0), "Dev wallet not set");
        uint256 _paymentBalance_ = _payment.balanceOf(address(this));
        uint256 _tokenBalance_ = _token.balanceOf(address(this));
        uint256 _tokenLiquidity_ = _paymentBalance_ / _openingPrice;
        require(_tokenLiquidity_ <= _tokenBalance_, "Insufficient token balance");
        _router.addLiquidity(
            address(_payment),
            address(_token),
            _paymentBalance_,
            _tokenLiquidity_,
            _paymentBalance_,
            _tokenLiquidity_,
            _devWallet,
            block.timestamp + 3600
        );
        _poolCreated = true;
    }

    /**
     * Withdraw.
     * @dev Withdrawas all funds from contract.
     */
    function withdraw() external onlyOwner
    {
        require(_devWallet != address(0), "Dev wallet not set");
        _payment.transfer(_devWallet, _payment.balanceOf(address(this)));
        _token.transfer(_devWallet, _token.balanceOf(address(this)));
    }
}
