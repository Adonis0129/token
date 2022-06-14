// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
// Interfaces.
import "./interfaces/IVault.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

/**
 * @title Furio Token
 * @author Steve Harmeyer
 * @notice This is the ERC20 contract for $FUR.
 */

/// @custom:security-contact security@furio.io
contract Token2 is BaseContract
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer external
    {
        __BaseContract_init();
        _properties.name = "Furio";
        _properties.symbol = "$FUR";
        _properties.decimals = 18;
        _properties.tax = 1000;
        _properties.devTax = 1000;
        _properties.vaultTax = 8000;
        _properties.pumpAndDumpTax = 5000;
        _properties.pumpAndDumpRate = 2500;
        _properties.sellCooldown = 300; // 5 minutes on dev
        //_properties.sellCooldown = 86400; // 24 Hour cooldown
    }

    /**
     * Properties struct.
     */
    struct Properties {
        string name;
        string symbol;
        uint8 decimals;
        uint256 tax;
        uint256 devTax;
        uint256 vaultTax;
        uint256 pumpAndDumpTax;
        uint256 pumpAndDumpRate;
        uint256 sellCooldown;
        uint256 totalSupply;
    }
    Properties private _properties;

    /**
     * Mappings.
     */
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _lastSale;

    /**
     * Events.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Sell(address indexed seller, uint256 sellAmount);
    event Tax(address indexed from, uint256 transferAmount, uint256 taxAmount);
    event PumpAndDump(address indexed seller, uint256 sellAmount, uint256 taxAmount);

    /**
     * Properties.
     * @return Properties Contract properties.
     */
    function getProperties() external view returns (Properties memory)
    {
        return _properties;
    }

    /**
     * Get last sale.
     * @param seller_ Seller address.
     * @return uint256 Timestamp of last sale.
     */
    function getLastSale(address seller_) public view returns (uint256)
    {
        return _lastSale[seller_];
    }

    /**
     * Sale cooldown.
     * @param seller_ Seller address.
     * @return bool True if in cooldown.
     */
    function saleCooldown(address seller_) public view returns (bool)
    {
        return getLastSale(seller_) > block.timestamp - _properties.sellCooldown + 60;
    }

    /**
     * Remaining cooldown.
     * @param seller_ Seller address.
     * @return uint256 Seconds until cooldown is over.
     */
    function remainingCooldown(address seller_) public view returns (uint256)
    {
        if(!saleCooldown(seller_)) {
            return 0;
        }
        return getLastSale(seller_) - (block.timestamp - _properties.sellCooldown);
    }

    /**
     * Name.
     * @return string Name of token.
     */
    function name() external view returns (string memory) {
        return _properties.name;
    }

    /**
     * Symbol.
     * @return string Symbol of token.
     */
    function symbol() external view returns (string memory) {
        return _properties.symbol;
    }

    /**
     * Decimals.
     * @return uint8 Token decimals.
     */
    function decimals() external view returns (uint8) {
        return _properties.decimals;
    }

    /**
     * Total supply.
     * @return uint256 Total tokens that exist.
     */
    function totalSupply() external view returns (uint256) {
        return _properties.totalSupply;
    }

    /**
     * Balance of.
     * @param address_ Owner address.
     * @return uint256 Number of tokens owned.
     */
    function balanceOf(address address_) external view returns (uint256) {
        return _balances[address_];
    }

    /**
     * Transfer tokens.
     * @param to_ To address.
     * @param amount_ Amount of tokens to transfer.
     * @return bool True if successful.
     */
    function transfer(address to_, uint256 amount_) external whenNotPaused returns (bool) {
        if(_isSale(msg.sender, to_)) {
            require(!saleCooldown(msg.sender), "Sell cooldown period is in effect");
            _lastSale[msg.sender] = block.timestamp;
            emit Sell(msg.sender, amount_);
        }
        _transfer(msg.sender, to_, _takeTaxes(msg.sender, to_, amount_));
        return true;
    }

    /**
     * Transfer from.
     * @param from_ Address of giver.
     * @param to_ Address of receiver.
     * @param amount_ Number of tokens to send.
     * @return bool True if successful.
     */
    function transferFrom(address from_, address to_, uint256 amount_) external whenNotPaused returns (bool) {
        if(_isSale(from_, to_)) {
            require(!saleCooldown(from_), "Sell cooldown period is in effect");
            _lastSale[from_] = block.timestamp;
            emit Sell(from_, amount_);
        }
        _spendAllowance(from_, msg.sender, amount_);
        _transfer(from_, to_, _takeTaxes(from_, to_, amount_));
        return true;
    }

    /**
     * Allowance.
     * @param owner_ Token owner.
     * @param spender_ Token spender.
     * @return uint256 Amount of tokens spender is allowed to spend.
     */
    function allowance(address owner_, address spender_) public view returns (uint256) {
        return _allowances[owner_][spender_];
    }

    /**
     * Approve.
     * @param spender_ Address of spender.
     * @param amount_ Tokens spender can spend.
     * @return bool True if successful.
     */
    function approve(address spender_, uint256 amount_) external whenNotPaused returns (bool) {
        _approve(msg.sender, spender_, amount_);
        return true;
    }

    /**
     * Increase allowance.
     * @param spender_ Spender address.
     * @param amount_ Amount of increase.
     * @return bool True if successful.
     */
    function increaseAllowance(address spender_, uint256 amount_) external whenNotPaused returns (bool) {
        _approve(msg.sender, spender_, allowance(msg.sender, spender_) + amount_);
        return true;
    }

    /**
     * Decrease allowance.
     * @param spender_ Spender address.
     * @param amount_ Amount of decrease.
     * @return bool True if successful.
     */
    function decreaseAllowance(address spender_, uint256 amount_) external whenNotPaused returns (bool) {
        uint256 _current_ = allowance(msg.sender, spender_);
        require(_current_ >= amount_, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender_, _current_ - amount_);
        }
        return true;
    }

    /**
     * -------------------------------------------------------------------------
     * INTERNAL FUNCTIONS
     * -------------------------------------------------------------------------
     */

    /**
     * Checks to see if an address is not part of the exchange.
     * @param address_ Address to check.
     * @return bool True if not part of the exchange.
     */
    function _isExchange(address address_) internal view returns (bool)
    {
        address _swap_ = addressBook.get("swap");
        address _pair_ = IUniswapV2Factory(addressBook.get("factory")).getPair(addressBook.get("payment"), address(this));
        return address_ == _swap_ || address_ == _pair_;
    }

    /**
     * Checks to see if a transfer is user to user.
     * @param from_ From address.
     * @param to_ To address.
     * @return bool True if user to user.
     */
    function _isUserToUser(address from_, address to_) internal view returns (bool)
    {
        return !_isExchange(from_) && !_isExchange(to_);
    }

    /**
     * Checks to see if transfer is a sale or not.
     * @param from_ From address.
     * @param to_ To address.
     * @return bool True if it's a sale.
     */
    function _isSale(address from_, address to_) internal view returns (bool)
    {
        return !_isExchange(from_) && _isExchange(to_);
    }

    /**
     * Take taxes.
     * @param from_ From address.
     * @param to_ To address.
     * @param amount_ Amount of the transfer.
     * @return uint256 Amount after taxes have been removed.
     */
    function _takeTaxes(address from_, address to_, uint256 amount_) internal returns (uint256)
    {
        if(from_ == addressBook.get("pool")) {
            // Liquidity pool.
            return amount_;
        }
        if(_isExchange(from_) && _isExchange(to_)) {
            return amount_;
        }
        if(from_ == addressBook.get("swap")) {
            // No tax for buys from swap.
            return amount_;
        }
        uint256 _taxes_ = amount_ * _properties.tax / 10000;
        _burn(from_, _taxes_);
        return amount_ - _taxes_;

        // Get vault and safe addresses.
        address _vault_ = addressBook.get("vault");
        address _safe_ = addressBook.get("safe");
        // Sells would be from the user (e.g. !swap and !pair)
        //if(_isSale(from_, to_)) {
            //_taxes_ += _pumpAndDumpTaxAmount(from_, amount_);
        //}
        uint256 _vaultTaxAmount_ = _vaultTaxAmount(_taxes_);
        uint256 _devTaxAmount_ = _devTaxAmount(_taxes_);
        _devTaxAmount_ += _taxes_ - (_vaultTaxAmount_ + _devTaxAmount_);
        _balances[from_] -= _taxes_;
        emit Tax(from_, amount_, _taxes_);
        _balances[_vault_] += _vaultTaxAmount_;
        _balances[_safe_] += _devTaxAmount_;
        return amount_ - _taxes_;
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
        IVault _vaultContract_ = IVault(addressBook.get("vault"));
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
     * Tax amount.
     * @param amount_ Transfer amount.
     * @return uint256 Tax amount.
     */
    function _taxAmount(uint256 amount_) internal view returns (uint256)
    {
        return amount_ * _properties.tax / 10000;
    }

    /**
     * Vault tax amount.
     * @param amount_ Total tax amount.
     * @return uint256 Tax amount.
     */
    function _vaultTaxAmount(uint256 amount_) internal view returns (uint256)
    {
        return amount_ * _properties.vaultTax / 10000;
    }

    /**
     * Dev tax amount.
     * @param amount_ Total tax amount.
     * @return uint256 Tax amount.
     */
    function _devTaxAmount(uint256 amount_) internal view returns (uint256)
    {
        return amount_ * _properties.devTax / 10000;
    }

    /**
     * Internal transfer.
     * @param from_ From address.
     * @param to_ To address.
     * @param amount_ Amount to transfer.
     */
    function _transfer(address from_, address to_, uint256 amount_) internal {
        require(from_ != address(0), "ERC20: transfer from_ the zero address");
        require(to_ != address(0), "ERC20: transfer to_ the zero address");
        require(_balances[from_] >= amount_, "ERC20: transfer amount_ exceeds balance");
        _balances[from_] -= amount_;
        _balances[to_] += amount_;
        emit Transfer(from_, to_, amount_);
    }

    /**
     * Mint.
     * @param to_ Recipient address.
     * @param amount_ Amount to mint.
     */
    function _mint(address to_, uint256 amount_) internal {
        require(to_ != address(0), "ERC20: mint to the zero address");
        _properties.totalSupply += amount_;
        _balances[to_] += amount_;
        emit Transfer(address(0), to_, amount_);
    }

    /**
     * Burn.
     * @param from_ From address.
     * @param amount_ Amount to burn.
     */
    function _burn(address from_, uint256 amount_) internal {
        require(from_ != address(0), "ERC20: burn from the zero address");
        require(_balances[from_] >= amount_, "ERC20: burn amount_ exceeds balance");
        _balances[from_] -= amount_;
        _properties.totalSupply -= amount_;
        emit Transfer(from_, address(0), amount_);
    }

    /**
     * Approve.
     * @param owner_ Owner address.
     * @param spender_ Spender address.
     * @param amount_ Approved amount.
     */
    function _approve(address owner_, address spender_, uint256 amount_) internal {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender_ != address(0), "ERC20: approve to the zero address");
        _allowances[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }

    /**
     * Spend allowance.
     * @param owner_ Owner address.
     * @param spender_ Spender address.
     * @param amount_ Amount to spend.
     */
    function _spendAllowance(address owner_, address spender_, uint256 amount_) internal {
        uint256 currentAllowance = allowance(owner_, spender_);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount_, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner_, spender_, currentAllowance - amount_);
            }
        }
    }

    /**
     * -------------------------------------------------------------------------
     * ADMIN FUNCTIONS.
     * -------------------------------------------------------------------------
     */
    function mint(address to_, uint256 quantity_) external {
        require(_canMint(msg.sender), "Unauthorized");
        _mint(to_, quantity_);
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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}
