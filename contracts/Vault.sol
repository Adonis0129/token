// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";

/**
 * @title Claim
 * @author Steve Harmeyer
 * @notice This contract handles presale NFT claims
 */

/// @custom:security-contact security@furio.io
contract Vault is BaseContract
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
     * Deposit.
     * @param owner_ Owner address.
     * @param quantity_ Token quantity.
     * @return bool True if successful.
     */
    function deposit(address owner_, uint256 quantity_) external returns (bool)
    {

    }
}
