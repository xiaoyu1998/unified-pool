// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

import "../error/Errors.sol";

import "../utils/Printer.sol";
//import "./IDex.sol";

contract DexUniswapV3 is IUniswapV3SwapCallback {
    using SafeCast for uint256;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    address internal _token0;
    address internal _token1;
    uint24 internal _fee;
    address internal _pool;

    constructor(
        address tokenA, 
        address tokenB,
        uint24 fee,
        address  pool
    ) {
        if (tokenA == tokenB){
            revert Errors.TokenCanNotSwapWithSelf(tokenA);
        }

        (_token0, _token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        _fee = fee;
        _pool = pool;
    } 

    function swapExactIn(
        address from,
        address tokenIn,
        uint256 amountIn,
        address to
    ) external {
        uint160 sqrtPriceLimitX96 = getSqrtPriceLimitX96(tokenIn);
        if (tokenIn == _token0) {
            return _swapExact0For1(from, _pool, amountIn, to, sqrtPriceLimitX96);
        } else if (tokenIn == _token1) {
            return _swapExact1For0(from, _pool, amountIn, to, sqrtPriceLimitX96);
        } 

        revert Errors.TokenNotMatch(_pool, _token0, _token1, tokenIn);   
    }  

    function swapExactOut(
        address from,
        address tokenIn,
        uint256 amountOut,
        address to
    ) external {
        uint160 sqrtPriceLimitX96 = getSqrtPriceLimitX96(tokenIn);
        if (tokenIn == _token0) {
            return _swap0ForExact1(from, _pool, amountOut, to, sqrtPriceLimitX96);
        } else if (tokenIn == _token1) {
            return _swap1ForExact0(from, _pool, amountOut, to, sqrtPriceLimitX96);
        } 

        revert Errors.TokenNotMatch(_pool, _token0, _token1, tokenIn);   
    }    

    function _swapExact0For1(
        address from,
        address pool,
        uint256 amount0In,
        address to,
        uint160 sqrtPriceLimitX96
    ) internal {
        IUniswapV3Pool(pool).swap(to, true, amount0In.toInt256(), sqrtPriceLimitX96, abi.encode(from));
    }

    function _swap0ForExact1(
        address from,
        address pool,
        uint256 amount1Out,
        address to,
        uint160 sqrtPriceLimitX96
    ) internal {
        IUniswapV3Pool(pool).swap(to, true, -amount1Out.toInt256(), sqrtPriceLimitX96, abi.encode(from));
    }

    function _swapExact1For0(
        address from,
        address pool,
        uint256 amount1In,
        address to,
        uint160 sqrtPriceLimitX96
    ) internal {
        IUniswapV3Pool(pool).swap(to, false, amount1In.toInt256(), sqrtPriceLimitX96, abi.encode(from));
    }

    function _swap1ForExact0(
        address from,
        address pool,
        uint256 amount0Out,
        address to,
        uint160 sqrtPriceLimitX96
    ) internal {
        IUniswapV3Pool(pool).swap(to, false, -amount0Out.toInt256(), sqrtPriceLimitX96, abi.encode(from));
    }

    function _swapToLowerSqrtPrice(
        address from,
        address pool,
        uint160 sqrtPriceX96,
        address to
    ) internal {
        IUniswapV3Pool(pool).swap(to, true, type(int256).max, sqrtPriceX96, abi.encode(from));
    }

    function _swapToHigherSqrtPrice(
        address from,
        address pool,
        uint160 sqrtPriceX96,
        address to
    ) internal {
        IUniswapV3Pool(pool).swap(to, false, type(int256).max, sqrtPriceX96, abi.encode(from));
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

    function getSqrtPriceLimitX96(address tokenIn) public view returns (uint160) {
        if (tokenIn == _token0) {
            return MIN_SQRT_RATIO + 1;
        } else if (tokenIn == _token1) {
            return MAX_SQRT_RATIO - 1;
        } else {
            revert Errors.TokenNotMatch(_pool, _token0, _token1, tokenIn); 
        }
    }

    // function getPrice() public view returns (uint160) {
    //    (    uint160 surtPriceX96,
    //         ,
    //         ,
    //         ,
    //         ,
    //         ,
    //         ,
    //    ) = IUniswapV3Pool(pool).slot0();

    // }

    function getPool() public view returns(address) {
        return _pool;
    }


}
