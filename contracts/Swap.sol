// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./abstracts/BaseContract.sol";
// INTERFACES
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Swap is BaseContract
{
    /**
     * Initialize contract.
     * @param safe_ The address for the Gnosis safe that will
     * be managing the contract.
     */
    function intialize(address safe_) initializer public virtual
    {
        __baseContract_init(safe_);
    }

    /**
     * @dev Constants.
     */
    uint256 public constant decimals = 18;
    address public constant deadWallet = 0x000000000000000000000000000000000000dEaD;

    /**
     * @dev Contract variables.
     */
    uint256 public maxBuy;
    uint256 public maxSell;
    uint256 public maxBalance;

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
