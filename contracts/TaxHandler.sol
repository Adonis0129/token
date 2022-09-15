// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "./interfaces/ISwapV2.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/**
 * @title Furio Taxes
 * @author Steve Harmeyer
 * @notice This is the contract that handles all FUR taxes.
 */

/// @custom:security-contact security@furio.io
contract TaxHandler is BaseContract
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
     * Taxes.
     */
    mapping (address => bool) private _isExempt;
    uint256 public lpTax;
    uint256 public vaultTax;

    /**
     * Addresses.
     */
    address public lpStakingAddress;
    address public safeAddress;
    address public vaultAddress;

    /**
     * Tokens.
     */
    IERC20 public fur;
    IERC20 public usdc;

    /**
     * Exchanges.
     */
    IUniswapV2Router02 public router;
    ISwapV2 public swap;

    /**
     * Last distribution.
     */
    uint256 public distributionInterval;
    uint256 public lastDistribution;

    /**
     * Check if address is exempt.
     * @param address_ Address to check.
     * @return bool True if address is exempt.
     */
    function isExempt(address address_) external view returns (bool)
    {
        return _isExempt[address_];
    }

    /**
     * Add tax exemption.
     * @param address_ Address to be exempt.
     */
    function addTaxExemption(address address_) external onlyOwner
    {
        _isExempt[address_] = true;
    }

    /**
     * Distribute taxes.
     */
    function distribute() external
    {
        if(lastDistribution + distributionInterval > block.timestamp) return;
        // Convert all FUR to USDC.
        uint256 _furBalance_ = fur.balanceOf(address(this));
        fur.approve(address(swap), _furBalance_);
        if(_furBalance_ > 0) swap.sell(_furBalance_);
        // Get USDC balance.
        uint256 _usdcBalance_ = usdc.balanceOf(address(this));
        // Calculate taxes.
        uint256 _vaultTax_ = _usdcBalance_ * vaultTax / 10000;
        uint256 _lpTax_ = _usdcBalance_ * lpTax / 10000;
        // Handle vault taxes.
        if(_vaultTax_ > 0) {
            // Swap USDC for FUR to cover vault taxes.
            usdc.approve(address(swap), _vaultTax_);
            swap.buy(address(usdc), _vaultTax_);
            // Transfer FUR to vault.
            fur.transfer(vaultAddress, fur.balanceOf(address(this)));
        }
        // Handle liquidity taxes.
        if(_lpTax_ > 0) {
            // Swap half of USDC for FUR in order to add liquidity.
            usdc.approve(address(swap), _lpTax_ / 2);
            swap.buy(address(usdc), _lpTax_ / 2);
            // Get output from swap.
            uint256 _newFurBalance_ = fur.balanceOf(address(this));
            // Add liquidity.
            usdc.approve(address(router), _lpTax_ / 2);
            fur.approve(address(router), _newFurBalance_);
            router.addLiquidity(
                address(usdc),
                address(fur),
                _lpTax_ / 2,
                _newFurBalance_,
                0,
                0,
                lpStakingAddress,
                block.timestamp
            );
        }
        // Transfer remaining USDC to safe
        usdc.transfer(safeAddress, usdc.balanceOf(address(this)));
        lastDistribution = block.timestamp;
    }

    /**
     * Setup.
     */
    function setup() external
    {
        // Addresses.
        lpStakingAddress = addressBook.get("lpStaking");
        safeAddress = addressBook.get("safe");
        vaultAddress = addressBook.get("vault");
        // Tokens.
        fur = IERC20(addressBook.get("token"));
        usdc = IERC20(addressBook.get("payment"));
        // Exchanges.
        router = IUniswapV2Router02(addressBook.get("router"));
        swap = ISwapV2(addressBook.get("swap"));
        // Exemptions.
        _isExempt[address(this)] = true;
        _isExempt[address(router)] = true;
        _isExempt[address(swap)] = true;
        _isExempt[lpStakingAddress] = true;
        _isExempt[safeAddress] = true;
        _isExempt[vaultAddress] = true;
        _isExempt[addressBook.get("downline")] = true;
        _isExempt[addressBook.get("liquidityManager")] = true;
        _isExempt[addressBook.get("pool")] = true;
        // Taxes.
        lpTax = 2000;
        vaultTax = 6000;
        // Distributions.
        distributionInterval = 2 hours;
    }
}
