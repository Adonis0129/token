// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

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
    }
}
