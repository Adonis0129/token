// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
// INTERFACES
import "./interfaces/IToken.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/**
 * @title Furio Swap
 * @author Steve Harmeyer
 * @notice This is the uinswap contract for $FUR.
 */

/// @custom:security-contact security@furio.io
contract FurioSwapV1 is BaseContract
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
     * Uniswap Router.
     */
    IUniswapV2Router02 public router;

    /**
     * Payment token.
     */
    IERC20 public payment;

    /**
     * Token.
     */
    IToken public token;

    /**
     * Limits.
     */
    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWalletBalance;

    /**
     * -------------------------------------------------------------------------
     * USER FUNCTIONS.
     * -------------------------------------------------------------------------
     */

    /**
     * Version.
     * @return uint256
     * @dev Returns the current contract version.
     */
     function version() external pure virtual returns (uint256)
     {
         return 1;
     }

    /**
     * Swap payment for token.
     */
    function swapPaymentForToken(uint256 amount_) external whenNotPaused returns (bool)
    {
        require(amount_ > 0, "Invalid amount");
        require(payment.transferFrom(address(msg.sender), address(this), amount_), "Payment transfer failed");
        address[] memory _path_ = new address[](2);
        _path_[0] = address(payment);
        _path_[1] = address(token);
        payment.approve(address(router), amount_);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount_,
            0,
            _path_,
            address(this),
            block.timestamp + 3600
        );
        uint256 _contractTokenBalance_ = token.balanceOf(address(this));
        uint256 _userTokenBalance_ = token.balanceOf(msg.sender);
        require(_contractTokenBalance_ <= maxBuyAmount, "Exceeds maximum buy amount");
        require(_userTokenBalance_ + _contractTokenBalance_ <= maxWalletBalance, "Exceeds maximum wallet balance");
        return token.transfer(msg.sender, _contractTokenBalance_);
    }

    /**
     * Swap native currency for tokens.
     */
    function swapNativeForTokens() external whenNotPaused payable returns (bool)
    {
        require(msg.value > 0, "Invalid amount");
        address[] memory _path_ = new address[](3);
        _path_[0] = router.WETH();
        _path_[1] = address(payment);
        _path_[2] = address(token);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens { value: msg.value } (
            0,
            _path_,
            address(this),
            block.timestamp + 3600
        );
        uint256 _contractTokenBalance_ = token.balanceOf(address(this));
        uint256 _userTokenBalance_ = token.balanceOf(msg.sender);
        require(_contractTokenBalance_ <= maxBuyAmount, "Exceeds maximum buy amount");
        require(_userTokenBalance_ + _contractTokenBalance_ <= maxWalletBalance, "Exceeds maximum wallet balance");
        return token.transfer(msg.sender, _contractTokenBalance_);
    }

    /**
     * Swap token for payment.
     */
    function swapTokenForPayment(uint256 amount_) external whenNotPaused
    {
        require(amount_ > 0, "Invalid amount");
        require(amount_ <= maxSellAmount, "Exceeds maximum sell amount");
        require(token.transferFrom(address(msg.sender), address(this), amount_), "Token transfer failed");
        uint256 _fees_ = sellerFees(msg.sender, amount_);
        uint256 _sellAmount_ = amount_ - _fees_;
        token.approve(address(router), _sellAmount_);
        address[] memory _path_ = new address[](2);
        _path_[0] = address(token);
        _path_[1] = address(payment);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _sellAmount_,
            0,
            _path_,
            address(msg.sender),
            block.timestamp + 3600
        );
    }

    /**
     * Swap token for native.
     */
    function swapTokenForNative(uint256 amount_) external whenNotPaused
    {
        require(amount_ > 0, "Invalid amount");
        require(amount_ <= maxSellAmount, "Exceeds maximum sell amount");
        require(token.transferFrom(address(msg.sender), address(this), amount_), "Token transfer failed");
        uint256 _fees_ = sellerFees(msg.sender, amount_);
        uint256 _sellAmount_ = amount_ - _fees_;
        token.approve(address(router), _sellAmount_);
        address[] memory _path_ = new address[](3);
        _path_[0] = address(token);
        _path_[1] = address(payment);
        _path_[2] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _sellAmount_,
            0,
            _path_,
            address(msg.sender),
            block.timestamp + 3600
        );
    }

    /**
     * Seller fees.
     */
    function sellerFees(address seller_, uint256 amount_) public returns (uint256)
    {
        // all tax gets split the same
        // 10% burn, 20% lp, 10% marketing, 60% vault
        // can only sell once every 24 hours
        // 10% base tax
        // ---------------------------------------------------------------------
        // Pump and dump taxes... (only applies to selling)
        // if they are selling > 25% of what they have in the vault, add an additional 40% (unless max payout reached)
        // ---------------------------------------------------------------------
        // whale taxes... (only applies to selling)
        // owns > 1% of total supply - 5% extra
        // owns > 2% of total supply - 10% extra
        // owns > 3% of total supply - 15% extra
        // owns > 4% of total supply - 20% extra
        // owns > 5% of total supply - 25% extra
        // owns > 6% of total supply - 30% extra
        // owns > 7% of total supply - 35% extra
        // owns > 8% of total supply - 40% extra
        // owns > 9% of total supply - 45% extra
        // owns > 10% of total supply - 50% extra
    }

    /**
     * -------------------------------------------------------------------------
     * INTERNAL FUNCTIONS.
     * -------------------------------------------------------------------------
     */

    /**
     * -------------------------------------------------------------------------
     * MODIFIERS.
     * -------------------------------------------------------------------------
     */

    /**
     * -------------------------------------------------------------------------
     * ADMIN FUNCTIONS.
     * -------------------------------------------------------------------------
     */

    /**
     * Set router.
     * @param address_ Address for Uniswap router.
     * @dev Sets the router.
     */
    function setRouter(address address_) external onlyOwner
    {
        router = IUniswapV2Router02(address_);
    }

    /**
     * Set payment token.
     * @param address_ Address for payment token contract.
     * @dev Sets the payment token address.
     */
    function setPayment(address address_) external onlyOwner
    {
        payment = IERC20(address_);
    }

    /**
     * Set token.
     * @param address_ Address for the token contract.
     * @dev Sets the token address.
     */
    function setToken(address address_) external onlyOwner
    {
        token = IToken(address_);
    }

    /**
     * -------------------------------------------------------------------------
     * HOOKS.
     * -------------------------------------------------------------------------
     */
}
