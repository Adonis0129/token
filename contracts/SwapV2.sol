// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
// INTERFACES
import "./interfaces/ILiquidityManager.sol";
import "./interfaces/ITaxHandler.sol";
import "./interfaces/IVault.sol";
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
contract SwapV2 is BaseContract
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
        furTax = 600; // 6%
        usdcTax = 400; // 4%
        pumpAndDumpMultiplier = 6; // Tax at 6x the normal rate (e.g. 60% instead of 10%)
        pumpAndDumpRate = 2500; // 25%
        cooldownPeriod = 1 days;
    }

    /**
     * Contracts.
     */
    IUniswapV2Factory public factory;
    IERC20 public fur;
    ILiquidityManager public liquidityManager;
    IUniswapV2Pair public pair;
    IUniswapV2Router02 public router;
    ITaxHandler public taxHandler;
    IERC20 public usdc;
    IVault public vault;

    /**
     * Taxes.
     */
    uint256 public furTax;
    uint256 public usdcTax;
    uint256 public pumpAndDumpMultiplier;
    uint256 public pumpAndDumpRate;

    /**
     * Cooldown.
     */
    uint256 public cooldownPeriod;
    mapping(address => bool) private _isExemptFromCooldown;
    mapping(address => uint256) public lastSell;

    /**
     * Liquidity manager.
     */
    bool public liquidityManagerEnabled;

    /**
     * Contract setup.
     */
    function setup() external
    {
        factory = IUniswapV2Factory(addressBook.get("factory"));
        fur = IERC20(addressBook.get("token"));
        liquidityManager = ILiquidityManager(addressBook.get("liquidityManager"));
        router = IUniswapV2Router02(addressBook.get("router"));
        taxHandler = ITaxHandler(addressBook.get("taxHandler"));
        usdc = IERC20(addressBook.get("usdc"));
        vault = IVault(addressBook.get("vault"));
        pair = IUniswapV2Pair(factory.getPair(address(fur), address(usdc)));
        _isExemptFromCooldown[address(this)] = true;
        _isExemptFromCooldown[address(liquidityManager)] = true;
        _isExemptFromCooldown[address(taxHandler)] = true;
        _isExemptFromCooldown[owner()] = true;
    }

    /**
     * Buy FUR.
     * @param payment_ Address of payment token.
     * @param amount_ Amount of tokens to spend.
     */
    function buy(address payment_, uint256 amount_) external whenNotPaused
    {
        // Buy FUR.
        uint256 _received_ = _buy(msg.sender, payment_, amount_);
        // Transfer received FUR to sender.
        require(fur.transfer(msg.sender, _received_), "Swap: transfer failed");
    }

    /**
     * Deposit buy.
     * @param payment_ Address of payment token.
     * @param amount_ Amount of payment.
     */
    function depositBuy(address payment_, uint256 amount_) external whenNotPaused
    {
        // Buy FUR.
        uint256 _received_ = _buy(msg.sender, payment_, amount_);
        // Deposit into vault.
        vault.depositFor(msg.sender, _received_, address(0));
    }

    /**
     * Deposit buy with referrer.
     * @param payment_ Address of payment token.
     * @param amount_ Amount of payment.
     * @param referrer_ Address of referrer.
     */
    function depositBuy(address payment_, uint256 amount_, address referrer_) external whenNotPaused
    {
        // Buy FUR.
        uint256 _received_ = _buy(msg.sender, payment_, amount_);
        // Deposit into vault.
        vault.depositFor(msg.sender, _received_, referrer_);
    }

    /**
     * Internal buy FUR.
     * @param buyer_ Buyer address.
     * @param payment_ Address of payment token.
     * @param amount_ Amount of tokens to spend.
     * @return uint256 Amount of FUR received.
     */
    function _buy(address buyer_, address payment_, uint256 amount_) internal returns (uint256)
    {
        // Convert payment to USDC.
        uint256 _usdcAmount_ = _buyUsdc(payment_, amount_, buyer_);
        // Get sender exempt status.
        bool _isExempt_ = taxHandler.isExempt(buyer_);
        // Calculate USDC taxes.
        uint256 _usdcTax_ = 0;
        if(!_isExempt_) _usdcTax_ = _usdcAmount_ * usdcTax / 10000;
        // Get current FUR balance.
        uint256 _furBalance_ = fur.balanceOf(address(this));
        // Swap USDC for FUR.
        _swap(address(usdc), address(fur), _usdcAmount_ - _usdcTax_);
        uint256 _furSwapped_ = fur.balanceOf(address(this)) - _furBalance_;
        // Calculate FUR taxes.
        uint256 _furTax_ = 0;
        if(!_isExempt_) _furTax_ = (_furSwapped_ * (10000 - usdcTax) / 10000) * furTax / 10000;
        // Transfer taxes to tax handler.
        if(_usdcTax_ > 0) usdc.transfer(address(taxHandler), _usdcTax_);
        if(_furTax_ > 0) fur.transfer(address(taxHandler), _furTax_);
        // Return amount.
        return _furSwapped_ - _furTax_;
    }

    /**
     * Internal buy USDC.
     * @param payment_ Address of payment token.
     * @param amount_ Amount of tokens to spend.
     * @param buyer_ Address of buyer.
     * @return uint256 Amount of USDC purchased.
     */
    function _buyUsdc(address payment_, uint256 amount_, address buyer_) internal returns (uint256)
    {
        // Instanciate payment token.
        IERC20 _payment_ = IERC20(payment_);
        // Get current payment balance.
        uint256 _paymentBalance_ = _payment_.balanceOf(address(this));
        // Transfer payment tokens to this address.
        require(_payment_.transferFrom(buyer_, address(this), amount_), "Swap: transfer failed");
        // If payment is already USDC, return.
        if(payment_ == address(usdc)) {
            return _payment_.balanceOf(address(this)) - _paymentBalance_;
        }
        // Get current USDC balance.
        uint256 _usdcBalance_ = usdc.balanceOf(address(this));
        // Swap payment for USDC.
        _swap(address(_payment_), address(usdc), amount_);
        // Return tokens received.
        return usdc.balanceOf(address(this)) - _usdcBalance_;
    }

    /**
     * Swap.
     * @param in_ Address of input token.
     * @param out_ Address of output token.
     * @param amount_ Amount of input tokens to swap.
     */
    function _swap(address in_, address out_, uint256 amount_) internal
    {
        if(liquidityManagerEnabled) {
            _swapThroughLiquidityManager(in_, out_, amount_);
        }
        else {
            _swapThroughUniswap(in_, out_, amount_);
        }
    }

    /**
     * Swap through uniswap.
     * @param in_ Input token address.
     * @param out_ Output token address.
     * @param amount_ Amount of input token.
     */
    function _swapThroughUniswap(address in_, address out_, uint256 amount_) internal
    {
        address[] memory _path_ = new address[](2);
        _path_[0] = in_;
        _path_[1] = out_;
        IERC20(in_).approve(address(router), amount_);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount_,
            0,
            _path_,
            address(this),
            block.timestamp + 3600
        );
    }

    /**
     * Swap through LMS.
     * @param in_ Input token address.
     * @param out_ Output token address.
     * @param amount_ Amount of input token.
     */
    function _swapThroughLiquidityManager(address in_, address out_, uint256 amount_) internal
    {
        if(in_ != address(fur) && out_ != address(fur)) {
            return _swapThroughUniswap(in_, out_, amount_);
        }
        IERC20(in_).approve(address(liquidityManager), amount_);
        uint256 _output_;
        if(in_ == address(fur)) {
            _output_ = sellOutput(amount_);
            liquidityManager.swapTokenForUsdc(address(this), amount_, 0);
        }
        else {
            _output_ = buyOutput(address(usdc), amount_);
            liquidityManager.swapUsdcForToken(address(this), amount_, 0);
        }
    }

    /**
     * On cooldown.
     * @param participant_ Address of participant.
     * @return bool True if on cooldown.
     */
    function onCooldown(address participant_) public view returns (bool)
    {
        return !_isExemptFromCooldown[participant_] && lastSell[participant_] + cooldownPeriod > block.timestamp;
    }

    /**
     * Sell FUR.
     * @param amount_ Amount of FUR to sell.
     */
    function sell(uint256 amount_) external whenNotPaused
    {
        // Check cooldown.
        if(!_isExemptFromCooldown[msg.sender]) {
            require(block.timestamp > lastSell[msg.sender] + cooldownPeriod, "Swap: cooldown");
        }
        // Get current FUR balance.
        uint256 _furBalance_ = fur.balanceOf(address(this));
        // Transfer FUR to this contract.
        require(fur.transferFrom(msg.sender, address(this), amount_), "Swap: transfer failed");
        // Get FUR received.
        uint256 _furReceived_ = fur.balanceOf(address(this)) - _furBalance_;
        // Get sender exempt status.
        bool _isExempt_ = taxHandler.isExempt(msg.sender);
        // Calculate tax rates.
        uint256 _furTaxRate_ = furTax;
        uint256 _usdcTaxRate_ = usdcTax;
        if(!_isExempt_) {
            // Check pump and dump protection.
            if(vault.participantBalance(msg.sender) * pumpAndDumpRate / 10000 < amount_) {
                _furTaxRate_ = furTax * pumpAndDumpMultiplier;
                _usdcTaxRate_ = usdcTax * pumpAndDumpMultiplier;
            }
        }
        // Calculate FUR taxes.
        uint256 _furTax_ = 0;
        if(!_isExempt_) _furTax_ = _furReceived_ * _furTaxRate_ / 10000;
        // Get current USDC balance.
        uint256 _usdcBalance_ = usdc.balanceOf(address(this));
        // Swap FUR for USDC.
        _swap(address(fur), address(usdc), _furReceived_ - _furTax_);
        uint256 _usdcSwapped_ = usdc.balanceOf(address(this)) - _usdcBalance_;
        // Calculate USDC taxes.
        uint256 _usdcTax_ = 0;
        if(!_isExempt_) _usdcTax_ = (_usdcSwapped_ * (10000 - _furTaxRate_) / 10000) * _usdcTaxRate_ / 10000;
        // Transfer taxes to tax handler.
        if(_furTax_ > 0) fur.transfer(address(taxHandler), _furTax_);
        if(_usdcTax_ > 0) usdc.transfer(address(taxHandler), _usdcTax_);
        // Update last sell timestamp.
        lastSell[msg.sender] = block.timestamp;
        // Transfer received USDC to sender.
        require(usdc.transfer(msg.sender, _usdcSwapped_ - _usdcTax_), "Swap: transfer failed");
    }

    /**
     * Enable LMS
     */
    function enableLiquidityManager() external onlyOwner
    {
        liquidityManager.enableLiquidityManager(true);
        liquidityManagerEnabled = true;
    }

    /**
     * Disable LMS
     */
    function disableLiquidtyManager() external onlyOwner
    {
        liquidityManager.enableLiquidityManager(false);
        liquidityManagerEnabled = false;
    }

    /**
     * Get token buy output.
     * @param payment_ Address of payment token.
     * @param amount_ Amount spent.
     * @return uint Amount of tokens received.
     */
    function buyOutput(address payment_, uint256 amount_) public view returns (uint256) {
        return
            _getOutput(
                payment_,
                address(fur),
                amount_
            );
    }

    /**
     * Get token sell output.
     * @param amount_ Amount sold.
     * @return uint Amount of tokens received.
     */
    function sellOutput(uint256 amount_) public view returns (uint256) {
        return
            _getOutput(
                address(fur),
                address(usdc),
                amount_
            );
    }

    /**
     * Get output.
     * @param in_ In token.
     * @param out_ Out token.
     * @param amount_ Amount in.
     * @return uint Estimated tokens received.
     */
    function _getOutput(
        address in_,
        address out_,
        uint256 amount_
    ) internal view returns (uint256) {
        address[] memory _path_ = new address[](2);
        _path_[0] = in_;
        _path_[1] = out_;
        uint256[] memory _outputs_ = router.getAmountsOut(amount_, _path_);
        return _outputs_[1];
    }
}
