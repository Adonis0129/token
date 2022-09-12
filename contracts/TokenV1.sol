// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IAddLiquidity.sol";
import "./interfaces/ITaxHandler.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/**
 * @title Furio Token
 * @author Steve Harmeyer
 * @notice This is the ERC20 contract for $FUR.
 */

/// @custom:security-contact security@furio.io
contract TokenV1 is BaseContract, ERC20Upgradeable {
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() public initializer {
        __BaseContract_init();
        __ERC20_init("Furio", "$FUR");
    }

    function setInit() external onlyOwner {
        _properties.tax = 1000;
        _properties.vaultTax = 6000;
        _properties.pumpAndDumpTax = 5000;
        _properties.pumpAndDumpRate = 2500;
        _properties.sellCooldown = 86400; // 24 Hour cooldown
        _inSwap = false;
        _lpRewardTax = 2000;
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

    mapping(address => uint256) private _lastSale; // ..........................DEPRECATED
    uint256 _lpRewardTax; // ...................................................DEPRECATED
    bool _inSwap; // ...........................................................DEPRECATED
    uint256 private _lastAddLiquidityTime; // ..................................DEPRECATED
    address _addLiquidityAddress; // ...........................................DEPRECATED
    address _lpStakingAddress; // ..............................................DEPRECATED

    /**
     * External contracts.
     */
    ITaxHandler private _taxHandler;
    address private _lmsAddress;

    /**
     * Get prooperties.
     * @return Properties Contract properties.
     */
    function getProperties() external view returns (Properties memory) {
        return _properties;
    }

    /**
     * _transfer override.
     * @param from_ From address.
     * @param to_ To address.
     * @param amount_ Transfer amount.
     */
    function _transfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal override {
        if(from_ == _properties.lpAddress) require(
            to_ == _properties.swapAddress ||
            to_ == _properties.poolAddress ||
            to_ == _lmsAddress,
        "No swaps from external contracts");
        if(to_ == _properties.lpAddress) require(
            from_ == _properties.swapAddress ||
            from_ == _properties.poolAddress ||
            from_ == _lmsAddress,
        "No swaps from external contracts");
        uint256 _taxes_ = 0;
        if(!_taxHandler.isExempt(from_) && !_taxHandler.isExempt(to_)) {
            _taxes_ = (amount_ * _properties.tax) / 10000;
            super._transfer(from_, address(_taxHandler), _taxes_);
        }
        return super._transfer(from_, to_, amount_ - _taxes_);
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
    function setTax(uint256 tax_) external onlyOwner {
        _properties.tax = tax_;
    }


    /**
     * Update addresses.
     * @dev Updates stored addresses.
     */
    function updateAddresses() public {
        IUniswapV2Factory _factory_ = IUniswapV2Factory(
            addressBook.get("factory")
        );
        _properties.lpAddress = _factory_.getPair(
            addressBook.get("payment"),
            address(this)
        );
        _properties.swapAddress = addressBook.get("swap");
        _properties.poolAddress = addressBook.get("pool");
        _properties.vaultAddress = addressBook.get("vault");
        _properties.safeAddress = addressBook.get("safe");
        _addLiquidityAddress = addressBook.get("addLiquidity");
        _lpStakingAddress = addressBook.get("lpStaking");
        _taxHandler = ITaxHandler(addressBook.get("taxHandler"));
        _lmsAddress = addressBook.get("liquidityManager");
    }

    /**
     * -------------------------------------------------------------------------
     * HOOKS.
     * -------------------------------------------------------------------------
     */

    /**
     * @dev Add whenNotPaused modifier to token transfer hook.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {}

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
    function _canMint(address address_) internal view returns (bool) {
        if (address_ == owner()) {
            return true;
        }
        if (address_ == addressBook.get("claim")) {
            return true;
        }
        if (address_ == addressBook.get("downline")) {
            return true;
        }
        if (address_ == addressBook.get("pool")) {
            return true;
        }
        if (address_ == addressBook.get("vault")) {
            return true;
        }
        return false;
    }
}
