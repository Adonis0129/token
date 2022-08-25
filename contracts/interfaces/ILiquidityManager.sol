// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILiquidityManager {
    function rebalance(uint256 amount, bool buyback) external;
    function swapBusdForToken(
        address to,
        uint256 amountIn,
        uint256 amountOutMin
    ) external;
    function swapTokenForBusd(
        address to,
        uint256 amountIn,
        uint256 amountOutMin
    ) external;
    function swapTokenForBusdToWallet(
        address from,
        address destination,
        uint256 tokenAmount,
        uint256 slippage
    ) external;
    function enableLiquidityManager(bool value) external;
}
