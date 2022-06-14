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
        __BaseContract_init();
        __ERC20_init("Furio", "$FUR");
        _properties.tax = 1000;
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
        uint256 vaultTax;
        uint256 pumpAndDumpTax;
        uint256 pumpAndDumpRate;
        uint256 sellCooldown;
        address lpAddress;
        address swapAddress;
        address poolAddress;
        address vaultAddress;
        address safeAddress;
    }
    Properties private _properties;

    /**
     * Mappings.
     */
    mapping(address => uint256) private _lastSale;

    /**
     * Event.
     */
    event Sell(address seller_, uint256 sellAmount_);
    event Tax(address indexed from_, uint256 transferAmount_, uint256 taxAmount_);
    event PumpAndDump(address indexed from_, uint256 transferAmount_, uint256 taxAmount_);

    /**
     * Get prooperties.
     * @return Properties Contract properties.
     */
    function getProperties() external view returns (Properties memory)
    {
        return _properties;
    }

    /**
     * _transfer override for taxes.
     * @param from_ From address.
     * @param to_ To address.
     * @param amount_ Transfer amount.
     */
    function _transfer(address from_, address to_, uint256 amount_) internal override
    {
        if(_properties.lpAddress == address(0)) {
            updateAddresses();
        }
        require(from_ != address(0), "ERC20: transfer from the zero address");
        require(to_ != address(0), "ERC20: transfer to the zero address");
        if(amount_ == 0) {
            return super._transfer(from_, to_, amount_);
        }
        if(from_ == _properties.poolAddress) {
            return super._transfer(from_, to_, amount_);
        }
        bool _takeFees_ = true;
        bool _takeHalfFees_ = false;
        bool _sell_ = false;
        if(from_ != _properties.lpAddress && to_ == _properties.swapAddress) {
            _takeHalfFees_ = true;
        }
        if(from_ == _properties.swapAddress && to_ == _properties.lpAddress) {
            _takeHalfFees_ = true;
        }
        if(from_ == _properties.lpAddress && to_ == _properties.swapAddress) {
            _takeFees_ = false;
        }
        if(from_ == _properties.swapAddress && to_ != _properties.lpAddress) {
            _takeFees_ = false;
        }
        if(!_isExchange(from_) && _isExchange(to_)) {
            _sell_ = true;
        }
        uint256 _taxes_;
        if(_takeFees_) {
            _taxes_ = amount_ * _properties.tax / 10000;
        }
        if(_sell_) {
            _taxes_ += _pumpAndDumpTaxAmount(from_, amount_);
        }
        if(_takeHalfFees_) {
            _taxes_ = _taxes_ / 2;
        }
        if(_taxes_ > 0) {
            uint256 _vaultTax_ = _taxes_ * _properties.vaultTax / 10000;
            super._transfer(from_, _properties.vaultAddress, _vaultTax_);
            super._transfer(from_, _properties.safeAddress, _taxes_ - _vaultTax_);
            amount_ -= _taxes_;
            emit Tax(from_, amount_, _taxes_);
        }
        super._transfer(from_, to_, amount_);
    }

    /**
     * Pump and dump tax amount.
     * @param from_ Sender.
     * @param amount_ Amount.
     * @return uint256 PnD tax amount.
     */
    function _pumpAndDumpTaxAmount(address from_, uint256 amount_) internal returns (uint256)
    {
        // Check vault.
        uint256 _taxAmount_;
        IVault _vaultContract_ = IVault(_properties.vaultAddress);
        if(!_vaultContract_.participantMaxed(from_)) {
            // Participant isn't maxed.
            if(amount_ > _vaultContract_.participantBalance(from_) * _properties.pumpAndDumpRate / 10000) {
                _taxAmount_ = amount_ * _properties.pumpAndDumpTax / 10000;
                emit PumpAndDump(from_, amount_, _taxAmount_);
            }
        }
        return _taxAmount_;
    }

    /**
     * Is sell?
     * @param from_ From address.
     * @param to_ To address.
     */
    function _isSell(address from_, address to_) internal view returns (bool)
    {
        return !_isExchange(from_) && _isExchange(to_);
    }

    /**
     * Is exchange?
     * @param address_ Address to check.
     * @return bool True if swap or lp
     */
    function _isExchange(address address_) internal view returns (bool)
    {
        return address_ == _properties.swapAddress || address_ == _properties.lpAddress;
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
     * Set vault tax.
     * @param vaultTax_ New vault tax rate.
     * @dev Sets the vault tax rate.
     */
    function setVaultTax(uint256 vaultTax_) external onlyOwner
    {
        require(vaultTax_ <= 10000, "Invalid amount");
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
     * Update addresses.
     * @dev Updates stored addresses.
     */
    function updateAddresses() public
    {
        IUniswapV2Factory _factory_ = IUniswapV2Factory(addressBook.get("factory"));
        _properties.lpAddress = _factory_.getPair(addressBook.get("payment"), address(this));
        _properties.swapAddress = addressBook.get("swap");
        _properties.poolAddress = addressBook.get("pool");
        _properties.vaultAddress = addressBook.get("vault");
        _properties.safeAddress = addressBook.get("safe");
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
}
