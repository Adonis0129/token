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
contract Token is BaseContract, ERC20Upgradeable
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __ERC20_init("Furio", "$FUR");
        __BaseContract_init();
        _tax = 10;
        _devTax = 10;
        _vaultTax = 80;
    }

    /**
     * Taxes.
     */
    uint256 private _tax;               // Total tax rate.
    uint256 private _devTax;            // Percent of tax collected for marketing/development.
    uint256 private _vaultTax;          // Percent of tax collected that goes to the vault.

    /**
     * Events.
     */
    event TaxUpdated(uint256 tax_);
    event DevTaxUpdated(uint256 devTax_);
    event VaultTaxUpdated(uint256 vaultTax_);
    event DevAddressUpdated(address devAddress_);
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
        return 100 - (_devTax + _vaultTax);
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
     * Vault tax.
     * @return uint256
     * @dev Returns the vault tax rate.
     */
    function vaultTax() external view returns (uint256)
    {
        return _vaultTax;
    }

    /**
     * Vault transfer.
     *
     */

    /**
     * -------------------------------------------------------------------------
     * INTERNAL FUNCTIONS.
     * -------------------------------------------------------------------------
     */

    /**
     * Transfer.
     */
    //function _transfer(address from_, address to_, uint256 amount_) internal override
    //{
        //address _safe_ = addressBook.get("safe");
        //address _vault_ = addressBook.get("vault");
        //// Get total tax amount
        //uint256 _taxAmount_ = amount_ * _tax / 100;
        //amount_ -= _taxAmount_;
        //// Calculate tax spend
        //uint256 _devAmount_ = _taxAmount_ * _devTax / 100;
        //uint256 _vaultAmount_ = _taxAmount_ * _vaultTax / 100;
        //uint256 _burnAmount_ = _taxAmount_ - (_devAmount_ + _vaultAmount_);
        //// Burn!
        ////super._burn(from_, _burnAmount_);
        //// Spend taxes
        //super._transfer(from_, _safe_, _devAmount_);
        //super._transfer(from_, _vault_, _vaultAmount_);
        //// Transfer tokens
        //super._transfer(from_, to_, amount_);
    //}

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
    function mint(address to_, uint256 quantity_) external {
        require(_canMint(msg.sender), "Unauthorized");
        super._mint(to_, quantity_);
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
     * Set dev tax.
     * @param devTax_ New dev tax rate.
     * @dev Sets the dev tax rate.
     */
    function setDevTax(uint256 devTax_) external onlyOwner
    {
        require(devTax_ + _vaultTax <= 100, "Invalid amount");
        _devTax = devTax_;
        emit DevTaxUpdated(devTax_);
    }

    /**
     * Set vault tax.
     * @param vaultTax_ New vault tax rate.
     * @dev Sets the vault tax rate.
     */
    function setVaultTax(uint256 vaultTax_) external onlyOwner
    {
        require(vaultTax_ + _devTax <= 100, "Invalid amount");
        _vaultTax = vaultTax_;
        emit VaultTaxUpdated(vaultTax_);
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

    /**
     * -------------------------------------------------------------------------
     * ACCESS.
     * -------------------------------------------------------------------------
     */

    /**
     * Can mint?
     * @param address_ Address of sender.
     * @return bool True if trusted.
     */
    function _canMint(address address_) internal view returns (bool)
    {
        if(address_ == addressBook.get("claim")) {
            return true;
        }
        if(address_ == addressBook.get("downline")) {
            return true;
        }
        if(address_ == addressBook.get("pool")) {
            return true;
        }
        if(address_ == addressBook.get("vault")) {
            return true;
        }
        return false;
    }
}
