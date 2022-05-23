// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
// Interfaces.
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/**
 * @title Furio Token
 * @author Steve Harmeyer
 * @notice This is the ERC20 contract for $FUR.
 */

/// @custom:security-contact security@furio.io
contract FurioToken is BaseContract, ERC20Upgradeable
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __ERC20_init("Furio", "$FUR");
        __BaseContract_init();
        _mint(owner(), 1000000000000000000000000);
        _tax = 10;
        _burnTax = 10;
        _devTax = 10;
        _liquidityTax = 20;
        _vaultTax = 60;
        _devAddress = 0x3bE201768ef0bd4aada533B4b0Ef2e89C7BB25C5;       // Dev wallet address.
        _payment = IERC20(0x581846B98000983e17472aedab56C54b5083fBA8);
        _factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        _router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _pair = _factory.createPair(_paymentAddress, address(this));
        _router.addLiquidity(
            _paymentAddress,
            address(this),
            2500000 * (10 ** 18),
            1000000 * (10 ** 18),
            2500000 * (10 ** 18),
            1000000 * (10 ** 18),
            _devAddress,
            block.timestamp + 3600
        );
    }

    /**
     * Taxes.
     */
    uint256 private _tax;               // Total tax rate.
    uint256 private _burnTax;           // Percent of tax collected that is burned.
    uint256 private _devTax;            // Percent of tax collected for marketing/development.
    uint256 private _liquidityTax;      // Percent of tax collected that goes into liquidity.
    uint256 private _vaultTax;          // Percent of tax collected that goes to the vault.

    /**
     * Addresses.
     */
    address private _paymentAddress;    // Payment token address.
    address private _devAddress;        // Dev wallet address.
    address private _liquidityAddress;  // Liquidity address.
    address private _vaultAddress;      // Vault address.
    address private _pair;              // Pair address.

    /**
     * Contracts.
     */
    IERC20 private _payment;
    IUniswapV2Factory private _factory;
    IUniswapV2Router02 private _router;

    /**
     * Events.
     */
    event TaxUpdated(uint256 tax_);
    event BurnTaxUpdated(uint256 burnTax_);
    event DevTaxUpdated(uint256 devTax_);
    event LiquidityTaxUpdated(uint256 liquidityTax_);
    event VaultTaxUpdated(uint256 vaultTax_);
    event FactoryAddressUpdated(address factoryAddress_);
    event RouterAddressUpdated(address routerAddress_);
    event PaymentAddressUpdated(address paymentAddress_);
    event DevAddressUpdated(address devAddress_);
    event LiquidityAddressUpdated(address liquidityAddress_);
    event VaultAddressUpdated(address vaultAddress_);
    event TaxesPayed(address spender_, uint256 tax_);

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
    function version() external pure returns (uint256)
    {
        return 1;
    }

    /**
     * Tax.
     * @return uint256
     * @dev Returns the default tax rate.
     */
    function tax() external view returns (uint256)
    {
        return _tax;
    }

    /**
     * Burn tax.
     * @return uint256
     * @dev Returns the burn tax rate.
     */
    function burnTax() external view returns (uint256)
    {
        return _burnTax;
    }

    /**
     * Dev tax.
     * @return uint256
     * @dev Returns the marketing/development tax rate.
     */
    function devTax() external view returns (uint256)
    {
        return _devTax;
    }

    /**
     * Liquidity tax.
     * @return uint256
     * @dev Returns the liquidity tax rate.
     */
    function liquidityTax() external view returns (uint256)
    {
        return _liquidityTax;
    }

    /**
     * Vault tax.
     * @return uint256
     * @dev Returns the vault tax rate.
     */
    function vaultTax() external view returns (uint256)
    {
        return _vaultTax;
    }

    /**
     * Dev address.
     * @return address
     * @dev Returns the address for the dev wallet.
     */
    function devAddress() external view returns (address)
    {
        return _devAddress;
    }

    /**
     * Liquidity address.
     * @return address
     * @dev Returns the address for the liquidity pool.
     */
    function liquidityAddress() external view returns (address)
    {
        return _liquidityAddress;
    }

    /**
     * Vault address.
     * @return address
     * @dev Returns the address for the vault contract.
     */
    function vaultAddress() external view returns (address)
    {
        return _vaultAddress;
    }

    /**
     * -------------------------------------------------------------------------
     * INTERNAL FUNCTIONS.
     * -------------------------------------------------------------------------
     */

    /**
     * Transfer.
     */
    function _transfer(address from_, address to_, uint256 amount_) internal virtual override
    {
        // Get total tax amount
        uint256 _taxAmount_ = amount_ * _tax / 100;
        amount_ -= _taxAmount_;
        // Calculate tax spend
        uint256 _burnAmount_ = _taxAmount_ * _burnTax / 100;
        uint256 _devAmount_ = _taxAmount_ * _devTax / 100;
        uint256 _liquidityAmount_ = _taxAmount_ * _liquidityTax / 100;
        uint256 _vaultAmount_ = _taxAmount_ * _vaultTax / 100;
        // Burn!
        super._burn(from_, _burnAmount_);
        // Spend taxes
        super._transfer(from_, _devAddress, _devAmount_);
        super._transfer(from_, _liquidityAddress, _liquidityAmount_);
        super._transfer(from_, _vaultAddress, _vaultAmount_);
        // Transfer tokens
        super._transfer(from_, to_, amount_);
    }

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
     * Create liquidity pool.
     * @dev Creates the liquidity pool on uniswap.
     */
    function createLiquidityPool() external onlyOwner
    {

    }

    /**
     * Set tax.
     * @param tax_ New tax rate.
     * @dev Sets the default tax rate.
     */
    function setTax(uint256 tax_) external onlyOwner
    {
        _tax = tax_;
        emit TaxUpdated(tax_);
    }

    /**
     * Set burn tax.
     * @param burnTax_ New burn tax rate.
     * @dev Sets the burn tax rate.
     */
    function setBurnTax(uint256 burnTax_) external onlyOwner
    {
        _burnTax = burnTax_;
        emit BurnTaxUpdated(burnTax_);
    }

    /**
     * Set dev tax.
     * @param devTax_ New dev tax rate.
     * @dev Sets the dev tax rate.
     */
    function setDevTax(uint256 devTax_) external onlyOwner
    {
        _devTax = devTax_;
        emit DevTaxUpdated(devTax_);
    }

    /**
     * Set liquidity tax.
     * @param liquidityTax_ New liquidity tax rate.
     * @dev Sets the liquidity tax rate.
     */
    function setLiquidityTax(uint256 liquidityTax_) external onlyOwner
    {
        _liquidityTax = liquidityTax_;
        emit LiquidityTaxUpdated(liquidityTax_);
    }

    /**
     * Set vault tax.
     * @param vaultTax_ New vault tax rate.
     * @dev Sets the vault tax rate.
     */
    function setVaultTax(uint256 vaultTax_) external onlyOwner
    {
        _vaultTax = vaultTax_;
        emit VaultTaxUpdated(vaultTax_);
    }

    /**
     * Set dev address.
     * @param devAddress_ New dev wallet address.
     * @dev Sets the address for the dev wallet.
     */
    function setDevAddress(address devAddress_) external onlyOwner
    {
        _devAddress = devAddress_;
        emit DevAddressUpdated(devAddress_);
    }

    /**
     * Set liquidity address.
     * @param liquidityAddress_ New liquidity address.
     * @dev Sets the address for the liquidity pool.
     */
    function setLiquidityAddress(address liquidityAddress_) external onlyOwner
    {
        _liquidityAddress = liquidityAddress_;
        emit LiquidityAddressUpdated(liquidityAddress_);
    }

    /**
     * Set vault address.
     * @param vaultAddress_ New vault address.
     * @dev Sets the address for the vault contract.
     */
    function setVaultAddress(address vaultAddress_) external onlyOwner
    {
        _vaultAddress = vaultAddress_;
        emit VaultAddressUpdated(vaultAddress_);
    }

    /**
     * -------------------------------------------------------------------------
     * HOOKS.
     * -------------------------------------------------------------------------
     */

    /**
     * @dev Add whenNotPaused modifier to token transfer hook.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
