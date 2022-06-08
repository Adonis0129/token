// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/**
 * @title Payment Token
 * @author Steve Harmeyer
 * @notice This is the ERC20 contract for fake USDC.
 */

/// @custom:security-contact security@furio.io
contract Payment is BaseContract, ERC20Upgradeable
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __ERC20_init("Fake USDC", "USDC");
        __BaseContract_init();
    }

    /**
     * Public mint function... mint as many as you want!
     */
    function mint(address to_, uint256 amount_) external {
        super._mint(to_, amount_);
    }
}
