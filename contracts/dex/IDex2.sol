// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

interface IDex2 {

    struct SwapParams2 {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        uint256 amount;
        uint160 sqrtPriceLimitX96;
    }

    function swapExactIn(
        address from,
        SwapParams2 memory params, 
        address to
    ) external;

    function swapExactOut(
        address from,
        SwapParams2 memory params,  
        address to
    ) external;

}
