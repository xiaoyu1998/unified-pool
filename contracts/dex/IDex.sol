// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

interface IDex {
    function swapExactIn(
        address from,
        address underlyingAssetIn,
        uint256 amountIn, 
        address to,
        uint256 sqrtPriceLimitX96
    ) external;

    function swapExactOut(
        address from,
        address underlyingAssetIn,
        uint256 amountOut, 
        address to,
        uint256 sqrtPriceLimitX96
    ) external;

    function getPool() external view returns(address);
    function getFeeAmount() external view returns(uint24);
    function getSwapFee(uint256) external view returns(uint256);
}


