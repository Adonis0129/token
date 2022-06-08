// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

/**
 * @title Furio Downline
 * @author Steve Harmeyer
 * @notice This is the ERC721 contract for downline NFTs.
 */

/// @custom:security-contact security@furio.io
contract Downline is BaseContract, ERC721Upgradeable
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __ERC721_init("Furio Downline", "$FURDOWNLINE");
        __BaseContract_init();
    }
}
