// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

interface IDex {

    function swapExactIn(
        address from,
        address underlyingAssetIn,
        uint256 amountIn, 
        address to
    ) external;

    function swapExactOut(
        address from,
        address underlyingAssetIn,
        uint256 amountOut, 
        address to
    ) external;

    function getSqrtPriceLimitX96(address tokenIn) external view returns (uint256);
}
