// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
// INTERFACES
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/**
 * @title Furio Swap
 * @author Steve Harmeyer
 * @notice This is the uinswap contract for $FUR.
 */

/// @custom:security-contact security@furio.io
contract Swap is BaseContract
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
     * Buy tokens.
     * @param paymentAmount_ Amount of payment.
     * @return bool True if successful.
     */
    function buy(uint256 paymentAmount_) external whenNotPaused returns (bool)
    {
        require(paymentAmount_ > 0, "Invalid amount");
        IERC20 _in_ = IERC20(addressBook.get("payment"));
        require(address(_in_) != address(0), "Payment not set");
        IERC20 _out_ = IERC20(addressBook.get("token"));
        require(address(_out_) != address(0), "Token not set");
        return(_swap(_in_, _out_, paymentAmount_));
    }

    /**
     * Sell tokens.
     * @param sellAmount_ Amount of tokens.
     * @return bool True if successful.
     */
    function sell(uint256 sellAmount_) external whenNotPaused returns (bool)
    {
        require(sellAmount_ > 0, "Invalid amount");
        IERC20 _in_ = IERC20(addressBook.get("token"));
        require(address(_in_) != address(0), "Token not set");
        IERC20 _out_ = IERC20(addressBook.get("payment"));
        require(address(_out_) != address(0), "Payment not set");
        return(_swap(_in_, _out_, sellAmount_));
    }

    /**
     * Get token buy output.
     * @param paymentAmount_ Amount spent.
     * @return uint Amount of tokens received.
     */
    function buyOutput(uint256 paymentAmount_) external view returns (uint)
    {
        require(paymentAmount_ > 0, "Invalid amount");
        return _getOutput(addressBook.get("payment"), addressBook.get("token"), paymentAmount_);
    }

    /**
     * Get token sell output.
     * @param sellAmount_ Amount sold.
     * @return uint Amount of tokens received.
     */
    function sellOutput(uint256 sellAmount_) external view returns (uint)
    {
        require(sellAmount_ > 0, "Invalid amount");
        return _getOutput(addressBook.get("token"), addressBook.get("payment"), sellAmount_);
    }

    /**
     * Swap.
     * @param in_ In token.
     * @param out_ Out token.
     * @param amount_ Amount in.
     * @return bool True if successful
     */
    function _swap(IERC20 in_, IERC20 out_, uint256 amount_) internal returns (bool)
    {
        IUniswapV2Router02 _router_ = IUniswapV2Router02(addressBook.get("router"));
        require(address(_router_) != address(0), "Router not set");
        require(in_.transferFrom(msg.sender, address(this), amount_), "In transfer failed");
        address[] memory _path_ = new address[](2);
        _path_[0] = address(in_);
        _path_[1] = address(out_);
        in_.approve(address(_router_), amount_);
        _router_.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount_,
            0,
            _path_,
            address(this),
            block.timestamp + 3600
        );
        uint256 _balance_ = out_.balanceOf(address(this));
        out_.approve(address(this), _balance_);
        return out_.transfer(msg.sender, _balance_);
    }

    /**
     * Get output.
     * @param in_ In token.
     * @param out_ Out token.
     * @param amount_ Amount in.
     * @return uint Estimated tokens received.
     */
    function _getOutput(address in_, address out_, uint256 amount_) internal view returns (uint)
    {
        IUniswapV2Router02 _router_ = IUniswapV2Router02(addressBook.get("router"));
        require(address(_router_) != address(0), "Router not set");
        address[] memory _path_ = new address[](2);
        _path_[0] = in_;
        _path_[1] = out_;
        uint[] memory _outputs_ = _router_.getAmountsOut(amount_, _path_);
        return _outputs_[1];
    }
}
