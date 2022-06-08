// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
// Interfaces.
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/**
 * @title Furio Pool
 * @author Steve Harmeyer
 * @notice This contract creates the liquidity pool for $FUR/USDC
 */

/// @custom:security-contact security@furio.io
contract Pool is BaseContract
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
     * -------------------------------------------------------------------------
     * GETTERS
     * -------------------------------------------------------------------------
     */

    /**
     * Price.
     * @return uint256 Price based off current token balances.
     * @dev Returns price based off current token balances.
     */
    function price() external view returns (uint256)
    {
        return (paymentBalance() / tokenBalance()) * (10 ** 18);
    }

    /**
     * Payment balance.
     * @return uint256 Payment token balance.
     * @dev Returns contract balance for payment token.
     */
    function paymentBalance() public view returns (uint256)
    {
        return _payment().balanceOf(address(this));
    }

    /**
     * Token balance.
     * @return uint256 Token balance.
     * @dev Returns contract token balance.
     */
    function tokenBalance() public view returns (uint256)
    {
        return _token().balanceOf(address(this));
    }

    /**
     * Create liquidity.
     * @dev Creates a liquidity pool with _payment and _token.
     */
    function createLiquidity() external onlyOwner
    {
        require(address(_payment()) != address(0), "Payment token not set");
        require(address(_token()) != address(0), "Token not set");
        require(_safe() != address(0), "Dev wallet not set");
        require(address(_router()) != address(0), "Router not set");
        _payment().approve(address(_router()), paymentBalance());
        _token().approve(address(_router()), tokenBalance());
        _router().addLiquidity(
            address(_payment()),
            address(_token()),
            paymentBalance(),
            tokenBalance(),
            0,
            0,
            _safe(),
            block.timestamp + 3600
        );
    }

    /**
     * Withdraw.
     * @dev Withdrawas all funds from contract.
     */
    function withdraw() external onlyOwner
    {
        address _safe_ = addressBook.get("safe");
        require(_safe_ != address(0), "Dev wallet not set");
        _payment().transfer(_safe_, paymentBalance());
        _token().transfer(_safe_, tokenBalance());
    }

    /**
     * -------------------------------------------------------------------------
     * INTERNAL FUNCTIONS.
     * -------------------------------------------------------------------------
     */

    /**
     * Payment token.
     * @return IERC20
     */
    function _payment() internal view returns (IERC20)
    {
        return IERC20(addressBook.get("payment"));
    }

    /**
     * FUR token.
     * @return IERC20
     */
    function _token() internal view returns (IERC20)
    {
        return IERC20(addressBook.get("token"));
    }

    /**
     * Safe.
     * @return address
     */
    function _safe() internal view returns (address)
    {
        return addressBook.get("safe");
    }

    /**
     * Router.
     * @return IUniswapV2Router02
     */
    function _router() internal view returns (IUniswapV2Router02)
    {
        return IUniswapV2Router02(addressBook.get("router"));
    }
}
