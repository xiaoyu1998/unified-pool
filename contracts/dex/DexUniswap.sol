// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/utils/math/Math.sol";
import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

import "../role/RoleModule.sol";
// import "../error/Errors.sol";
// import "../utils/Printer.sol";
import './uniswapV3/PeripheryImmutableState.sol';
import './uniswapV3/PoolAddress.sol';
import './uniswapV3/CallbackValidation.sol';
import "./IDex2.sol";

contract DexUniswap is IUniswapV3SwapCallback, PeripheryImmutableState, IDex2, RoleModule {
    using SafeCast for uint256;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    uint24 internal feeAmount; 

    constructor(
        RoleStore _roleStore,
        address _factory,
        uint24 _feeAmount
    ) RoleModule(_roleStore) PeripheryImmutableState(_factory) {
        feeAmount = _feeAmount;
    }

    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) private view returns (address) {
        return PoolAddress.computeAddress(factory, PoolAddress.getPoolKey(tokenA, tokenB, fee));
    } 

    /// @inheritdoc IDex2
    function swapExactIn(
        address from,
        address tokenIn,
        address tokenOut,
        uint256 amount,
        uint256 sqrtPriceLimitX96,
        address to
    ) external override onlyController {
        bool zeroForOne = tokenIn < tokenOut;
        address pool = getPool(tokenIn, tokenOut, feeAmount);
        uint160 priceLimit = sqrtPriceLimitX96 == 0
                                ? (zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1)
                                : uint160(sqrtPriceLimitX96);
        if (zeroForOne) {
            return _swapExact0For1(from, pool, amount, to, priceLimit);
        } else {
            return _swapExact1For0(from,pool, amount, to, priceLimit);
        } 
    }  
    
    /// @inheritdoc IDex2
    function swapExactOut(
        address from,
        address tokenIn,
        address tokenOut,
        uint256 amount,
        uint256 sqrtPriceLimitX96,
        address to
    ) external override onlyController {
        bool zeroForOne = tokenIn < tokenOut;
        address pool = getPool(tokenIn, tokenOut, feeAmount);
        uint160 priceLimit = sqrtPriceLimitX96 == 0
                                ? (zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1)
                                : uint160(sqrtPriceLimitX96);
        if (zeroForOne) {
            return _swap0ForExact1(from, pool, amount, to, priceLimit);
        } else {
            return _swap1ForExact0(from, pool, amount, to, priceLimit);
        }
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
        emit SwapCallback(amount0Delta, amount1Delta);

        address token0 = IUniswapV3Pool(msg.sender).token0();
        address token1 = IUniswapV3Pool(msg.sender).token1();
        CallbackValidation.verifyCallback(factory, token0, token1, feeAmount);

        if (amount0Delta > 0) {
            IERC20(token0).transferFrom(sender, msg.sender, uint256(amount0Delta));
        } else if (amount1Delta > 0) {
            IERC20(token1).transferFrom(sender, msg.sender, uint256(amount1Delta));
        } else {
            // if both are not gt 0, both must be 0.
            assert(amount0Delta == 0 && amount1Delta == 0);
        }
    }

    /// @inheritdoc IDex2
    function getPool(address tokenA, address tokenB) public view override returns(address) {
        return PoolAddress.computeAddress(factory, PoolAddress.getPoolKey(tokenA, tokenB, feeAmount));
    }
    
    /// @inheritdoc IDex2
    function getFeeAmount() public view override returns(uint24) {
        return feeAmount;
    }
    
    /// @inheritdoc IDex2
    function getSwapFee(uint256 amountIn) public view override returns(uint256) {
        return Math.mulDiv(amountIn, feeAmount, 1e6);
    }


}
