// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
// Interfaces.
import "./interfaces/IVault.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

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
        _properties.tax = 1000;
        _properties.devTax = 1000;
        _properties.vaultTax = 8000;
        _properties.pumpAndDumpTax = 5000;
        _properties.pumpAndDumpRate = 2500;
        _properties.sellCooldown = 300; // 5 Minutes on dev
        //_properties.sellCooldown = 86400; // 24 Hour cooldown
    }

    /**
     * Properties struct.
     */
    struct Properties {
        uint256 tax;
        uint256 devTax;
        uint256 vaultTax;
        uint256 pumpAndDumpTax;
        uint256 pumpAndDumpRate;
        uint256 sellCooldown;
    }
    Properties private _properties;

    /**
     * Sell timestamps.
     */
    mapping(address => uint256) private _lastSale;

    /**
     * Event.
     */
    event Sell(address seller_, uint256 sellAmount_);
    event PumpAndDump(address seller_, uint256 sellAmount_, uint256 vaultBalance_);

    /**
     * Get prooperties.
     * @return Properties Contract properties.
     */
    function getProperties() external view returns (Properties memory)
    {
        return _properties;
    }

    /**
     * Override transfer for taxes.
     * @param to_ To address.
     * @param amount_ Amount to transfer.
     * @return bool True if successful.
     */
    function transfer(address to_, uint256 amount_) public override returns (bool) {
        uint256 _adjustedAmount_ = _takeTaxes(msg.sender, to_, amount_);
        super._transfer(msg.sender, to_, _adjustedAmount_);
        return true;
    }

    /**
     * Override transferFrom for taxes.
     * @param from_ From address.
     * @param to_ To address.
     * @param amount_ Amount to transfer.
     * @return bool True if successful.
     */
    function transferFrom(address from_, address to_, uint256 amount_) public override returns (bool)
    {
        super._spendAllowance(from_, msg.sender, amount_);
        uint256 _adjustedAmount_ = _takeTaxes(from_, to_, amount_);
        super._transfer(from_, to_, _adjustedAmount_);
        return true;
    }

    /**
     * -------------------------------------------------------------------------
     * INTERNAL FUNCTIONS.
     * -------------------------------------------------------------------------
     */

    /**
     * Take taxes.
     * @param from_ From address.
     * @param to_ To address.
     * @param amount_ Amount of the transfer.
     * @return uint256 Amount after taxes have been removed.
     */
    function _takeTaxes(address from_, address to_, uint256 amount_) internal returns (uint256)
    {
        address _safe_ = addressBook.get("safe");
        address _vault_ = addressBook.get("vault");
        address _swap_ = addressBook.get("swap");
        address _pool_ = addressBook.get("pool");
        address _pair_ = IUniswapV2Factory(addressBook.get("factory")).getPair(addressBook.get("payment"), address(this));
        bool _sell_ = false;
        if(from_ == _pair_ && to_ == _swap_) {
            // NO TAX
            return amount_;
        }
        if(from_ == _swap_ && to_ != _pair_) {
            // NO TAX
            return amount_;
        }
        if(to_ == _pool_ || from_ == _pool_) {
            return amount_;
        }
        if((from_ != _pair_ && to_ == _swap_) || (from_ != _swap_ && to_ == _pair_)) {
            // IT'S A SELL!
            _sell_ = true;
            require(block.timestamp - _properties.sellCooldown >= _lastSale[from_], "Sell cooldown period is in effect");
            _lastSale[from_] = block.timestamp;
        }
        uint256 _pndTax_ = 0;
        if(_sell_) {
            IVault _vaultContract_ = IVault(_vault_);
            uint256 _balance_ = _vaultContract_.participantBalance(from_);
            uint256 _maximum_ = _balance_ * _properties.pumpAndDumpRate / 10000;
            if(amount_ > _maximum_ && !_vaultContract_.participantMaxed(from_)) {
                _pndTax_ = _properties.pumpAndDumpTax;
                emit PumpAndDump(from_, amount_, _balance_);
            }
            emit Sell(from_, amount_);
        }
        uint256 _taxAmount_ = amount_ * (_properties.tax + _pndTax_) / 10000;
        uint256 _devTaxAmount_ = _taxAmount_ * _properties.devTax / 10000;
        uint256 _vaultTaxAmount_ = _taxAmount_ * _properties.vaultTax / 10000;
        uint256 _burnTaxAmount_ = _taxAmount_ - _devTaxAmount_ - _vaultTaxAmount_;
        if(_devTaxAmount_ > 0) {
            super._transfer(from_, _safe_, _devTaxAmount_);
        }
        if(_vaultTaxAmount_ > 0) {
            super._transfer(from_, _vault_, _vaultTaxAmount_);
        }
        if(_burnTaxAmount_ > 0) {
            super._burn(from_, _burnTaxAmount_);
        }
        return amount_ - _taxAmount_;
    }

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
        _properties.tax = tax_;
    }

    /**
     * Set dev tax.
     * @param devTax_ New dev tax rate.
     * @dev Sets the dev tax rate.
     */
    function setDevTax(uint256 devTax_) external onlyOwner
    {
        require(devTax_ + _properties.vaultTax <= 10000, "Invalid amount");
        _properties.devTax = devTax_;
    }

    /**
     * Set vault tax.
     * @param vaultTax_ New vault tax rate.
     * @dev Sets the vault tax rate.
     */
    function setVaultTax(uint256 vaultTax_) external onlyOwner
    {
        require(vaultTax_ + _properties.devTax <= 10000, "Invalid amount");
        _properties.vaultTax = vaultTax_;
    }

    /**
     * Set pump and dump tax.
     * @param pumpAndDumpTax_ New vault tax rate.
     * @dev Sets the pump and dump tax rate.
     */
    function setPumpAndDumpTax(uint256 pumpAndDumpTax_) external onlyOwner
    {
        _properties.pumpAndDumpTax = pumpAndDumpTax_;
    }

    /**
     * Set pump and dump rate.
     * @param pumpAndDumpRate_ New vault Rate rate.
     * @dev Sets the pump and dump Rate rate.
     */
    function setPumpAndDumpRate(uint256 pumpAndDumpRate_) external onlyOwner
    {
        _properties.pumpAndDumpRate = pumpAndDumpRate_;
    }

    /**
     * Set sell cooldown period.
     * @param sellCooldown_ New cooldown rate.
     * @dev Sets the cooldown rate.
     */
    function setSellCooldown(uint256 sellCooldown_) external onlyOwner
    {
        _properties.sellCooldown = sellCooldown_;
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
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
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
        if(address_ == owner()) {
            return true;
        }
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

    /**
     * -------------------------------------------------------------------------
     * HELPERS.
     * -------------------------------------------------------------------------
     */
}
