// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
//import '@uniswap/v3-core/contracts/libraries/SafeCast.sol';
// import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol';
import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

import "../utils/Printer.sol";

contract UniswapV3Callee is IUniswapV3MintCallback, IUniswapV3SwapCallback {
    using SafeCast for uint256;

    function swapExact0For1(
        address pool,
        uint256 amount0In,
        address recipient,
        uint160 sqrtPriceLimitX96
    ) external {
        IUniswapV3Pool(pool).swap(recipient, true, amount0In.toInt256(), sqrtPriceLimitX96, abi.encode(msg.sender));
    }

    function swap0ForExact1(
        address pool,
        uint256 amount1Out,
        address recipient,
        uint160 sqrtPriceLimitX96
    ) external {
        IUniswapV3Pool(pool).swap(recipient, true, -amount1Out.toInt256(), sqrtPriceLimitX96, abi.encode(msg.sender));
    }

    function swapExact1For0(
        address pool,
        uint256 amount1In,
        address recipient,
        uint160 sqrtPriceLimitX96
    ) external {
        IUniswapV3Pool(pool).swap(recipient, false, amount1In.toInt256(), sqrtPriceLimitX96, abi.encode(msg.sender));
    }

    function swap1ForExact0(
        address pool,
        uint256 amount0Out,
        address recipient,
        uint160 sqrtPriceLimitX96
    ) external {
        IUniswapV3Pool(pool).swap(recipient, false, -amount0Out.toInt256(), sqrtPriceLimitX96, abi.encode(msg.sender));
    }

    function swapToLowerSqrtPrice(
        address pool,
        uint160 sqrtPriceX96,
        address recipient
    ) external {
        IUniswapV3Pool(pool).swap(recipient, true, type(int256).max, sqrtPriceX96, abi.encode(msg.sender));
    }

    function swapToHigherSqrtPrice(
        address pool,
        uint160 sqrtPriceX96,
        address recipient
    ) external {
        IUniswapV3Pool(pool).swap(recipient, false, type(int256).max, sqrtPriceX96, abi.encode(msg.sender));
    }

    event SwapCallback(int256 amount0Delta, int256 amount1Delta);

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        address sender = abi.decode(data, (address));

        Printer.log("-------------------------uniswapV3SwapCallback--------------------------"); 
        Printer.log("amount0Delta", amount0Delta);  
        Printer.log("amount1Delta", amount1Delta); 
        Printer.log("token0", IERC20Metadata(IUniswapV3Pool(msg.sender).token0()).symbol()); 
        Printer.log("token1", IERC20Metadata(IUniswapV3Pool(msg.sender).token1()).symbol());  

        emit SwapCallback(amount0Delta, amount1Delta);

        if (amount0Delta > 0) {
            IERC20(IUniswapV3Pool(msg.sender).token0()).transferFrom(sender, msg.sender, uint256(amount0Delta));
        } else if (amount1Delta > 0) {
            IERC20(IUniswapV3Pool(msg.sender).token1()).transferFrom(sender, msg.sender, uint256(amount1Delta));
        } else {
            // if both are not gt 0, both must be 0.
            assert(amount0Delta == 0 && amount1Delta == 0);
        }
    }

    function mint(
        address pool,
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external {
        // Printer.log("-------------------------uniswapV3MintCallback--------------------------"); 
        // Printer.log("pool", pool);
        // Printer.log("recipient", recipient); 
        // Printer.log("tickLower", int256(tickLower));  
        // Printer.log("tickUpper", int256(tickUpper));  
        // Printer.log("amount", uint256(amount));  
        IUniswapV3Pool(pool).mint(recipient, tickLower, tickUpper, amount, abi.encode(msg.sender));
    }

    event MintCallback(uint256 amount0Owed, uint256 amount1Owed);

    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external override {
        address sender = abi.decode(data, (address));
        Printer.log("-------------------------uniswapV3MintCallback--------------------------"); 
        Printer.log("sender", sender);
        Printer.log("amount0Owed", amount0Owed); 
        Printer.log("amount1Owed", amount1Owed);  
        Printer.log("token0", IERC20Metadata(IUniswapV3Pool(msg.sender).token0()).symbol()); 
        Printer.log("token1", IERC20Metadata(IUniswapV3Pool(msg.sender).token1()).symbol()); 

        emit MintCallback(amount0Owed, amount1Owed);
        if (amount0Owed > 0)
            IERC20(IUniswapV3Pool(msg.sender).token0()).transferFrom(sender, msg.sender, amount0Owed);
        if (amount1Owed > 0)
            IERC20(IUniswapV3Pool(msg.sender).token1()).transferFrom(sender, msg.sender, amount1Owed);
    }

}
