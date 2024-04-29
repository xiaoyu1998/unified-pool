// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

interface IDex {

    function swap(
        address from,
        address underlyingAssetIn,
        uint256 amountIn, 
        address to,
        uint160 sqrtPriceLimitX96
    ) external;

    function getSqrtPriceLimitX96(address tokenIn) external view returns (uint256);
}
