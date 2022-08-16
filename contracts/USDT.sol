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
contract USDT is BaseContract, ERC20Upgradeable
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
        __ERC20_init("USDT", "USDT");
    }

    /**
     * Mint USDC.
     * @param amount_ Amount to mint (no decimals)
     */
    function mint(uint256 amount_) external
    {
        require(amount_ > 0, "Invalid amount");
        _mint(msg.sender, amount_ * (10 ** 18));
    }
}
