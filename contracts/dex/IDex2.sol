// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

interface IDex2 {
    function swapExactIn(
        address from,
        address tokenIn,
        address tokenOut,
        uint256 amount,
        uint256 sqrtPriceLimitX96,
        address to
    ) external;

    function swapExactOut(
        address from,
        address tokenIn,
        address tokenOut,
        uint256 amount,
        uint256 sqrtPriceLimitX96,
        address to
    ) external;

    function getPool(address tokenA, address tokenB) external view returns(address);
    function getFeeAmount() external view returns(uint24);
    function getSwapFee(uint256) external view returns(uint256);

}
