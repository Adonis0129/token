// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

abstract contract BaseContract is Initializable, UUPSUpgradeable, OwnableUpgradeable
{
    /**
     * Contract initializer.
     * @param safe_ The address of the Gnosis safe that will
     * be managing the contract.
     * @dev Calls all parent initializers and sets
     * the owner to the Gnosis Safe address.
     */
    function __baseContract_init(address safe_) internal onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
        transferOwnership(safe_);
    }

    /**
     * Overrideable initializer.
     * @param safe_ The address of the Gnosis safe that will
     * be managing the contract.
     * @dev Calls the __baseContract_init function.
     */
    function initialize(address safe_) initializer public virtual
    {
        __baseContract_init(safe_);
    }
}
