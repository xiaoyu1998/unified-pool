// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../data/DataStore.sol";
import "../data/Keys.sol";
import "../error/Errors.sol";

import "../pool/Pool.sol";
import "../pool/PoolCache.sol";
import "../pool/PoolUtils.sol";
import "../pool/PoolStoreUtils.sol";
import "../token/IPoolToken.sol";
import "../token/IDebtToken.sol";

import "../position/Position.sol";
import "../position/PositionUtils.sol";
import "../position/PositionStoreUtils.sol";
import "../oracle/OracleUtils.sol";
import "../utils/WadRayMath.sol";
import "../dex/DexStoreUtils.sol";
import "../dex/IDex.sol";

import "../event/EventEmitter.sol";
import "./SwapEventUtils.sol";

// @title SwapUtils
// @dev Library for swap functions, to help with the swaping of liquidity
// into a market in return for market tokens
library SwapUtils {
    using Pool for Pool.Props;
    using PoolCache for PoolCache.Props;
    using Position for Position.Props;
    using WadRayMath for uint256;
    using PoolConfigurationUtils for uint256;

    struct SwapParams {
        address underlyingAssetIn;
        address underlyingAssetOut;
        uint256 amountIn;
        uint256 sqrtPriceLimitX96;
    }

    struct ExecuteSwapParams {
        address dataStore;
        address eventEmitter;
        address underlyingAssetIn;
        address underlyingAssetOut;
        uint256 amountIn;
        uint256 sqrtPriceLimitX96;
    }

    // // @dev executes a swap
    // // @param account the swap account
    // // @param params ExecuteSwapParams
    // function executeSwap(address account, ExecuteSwapParams calldata params) external {
    //     _executeSwap(account, params);
    // }

    // @dev executes a swap
    // @param account the swap account
    // @param params ExecuteSwapParams
    function executeSwap(address account, ExecuteSwapParams calldata params) external returns(uint256) {
        Printer.log("-------------------------executeSwap--------------------------");
        (   Pool.Props memory poolIn,
            PoolCache.Props memory poolCacheIn,
            address poolKeyIn,
            bool poolInIsUsd
        ) = PoolUtils.updatePoolAndCache(params.dataStore, params.underlyingAssetIn);
        (   Pool.Props memory poolOut,
            PoolCache.Props memory poolCacheOut,
            address poolKeyOut,
            bool poolOutIsUsd
        ) = PoolUtils.updatePoolAndCache(params.dataStore, params.underlyingAssetOut);

        bytes32 positionKeyIn = Keys.accountPositionKey(params.underlyingAssetIn, account);
        Position.Props memory positionIn  = PositionStoreUtils.get(params.dataStore, positionKeyIn);
        (   Position.Props memory positionOut,
            bytes32 positionKeyOut
        ) = PositionUtils.getOrInit(
            account,
            params.dataStore, 
            params.underlyingAssetOut, 
            Position.PositionTypeLong,
            poolOutIsUsd
        );

        IPoolToken poolTokenIn  = IPoolToken(poolIn.poolToken);
        IPoolToken poolTokenOut  = IPoolToken(poolOut.poolToken);
        uint256 amountIn = params.amountIn;
        uint256 collateralAmount = poolTokenIn.balanceOfCollateral(account);
        if( amountIn > collateralAmount){
            amountIn = collateralAmount;
        }
        
        address dex = DexStoreUtils.get(params.dataStore, params.underlyingAssetIn, params.underlyingAssetOut);
        SwapUtils.validateSwap( 
            account, 
            params.dataStore, 
            positionIn, 
            positionOut, 
            poolIn, 
            poolOut,
            amountIn,
            dex
        );

        Printer.log("-------------------------swapStart--------------------------");
        //swap
        poolTokenIn.approveLiquidity(dex, amountIn);
        IDex(dex).swap(
            address(poolTokenIn), 
            params.underlyingAssetIn, 
            amountIn, 
            address(poolTokenOut), 
            uint160(params.sqrtPriceLimitX96)
        );
        Printer.log("-------------------------swapEnd--------------------------");
        //TODO:should check the amountIn has been exactly swapped in, and remove allowance
        poolTokenIn.syncUnderlyingAssetBalance();

        //update collateral
        uint256 amountOut = poolTokenOut.recordTransferIn(params.underlyingAssetOut);
        poolTokenIn.removeCollateral(account, amountIn);//this line will assert if account InsufficientCollateralAmount
        poolTokenOut.addCollateral(account, amountOut);
        
        //update position price
        if (poolInIsUsd || poolOutIsUsd) {
            uint256 price = OracleUtils.calcPrice(
                amountIn,
                PoolConfigurationUtils.getDecimals(poolIn.configuration), 
                amountOut,
                PoolConfigurationUtils.getDecimals(poolOut.configuration),
                poolOutIsUsd
            );
            
            if (poolInIsUsd && !poolOutIsUsd) { //long out
                PositionUtils.longPosition(positionOut, price, amountOut);
            }

            if (!poolInIsUsd && poolOutIsUsd) { //Short in
                PositionUtils.shortPosition(positionIn,  price, amountIn);
            } 
        }

        //update postions
        PositionStoreUtils.set(
            params.dataStore, 
            positionKeyIn, 
            positionIn
        );
        PositionStoreUtils.set(
            params.dataStore, 
            positionKeyOut, 
            positionOut
        );

        // PoolUtils.updateInterestRates(
        //     poolIn,
        //     poolCacheIn, 
        //     params.underlyingAssetIn
        // );
        PoolStoreUtils.set(
            params.dataStore, 
            poolKeyIn, 
            poolIn
        );

        // PoolUtils.updateInterestRates(
        //     poolOut,
        //     poolCacheOut, 
        //     params.underlyingAssetOut
        // );
        PoolStoreUtils.set(
            params.dataStore, 
            poolKeyOut, 
            poolOut
        );

        SwapEventUtils.emitSwap(
            params.eventEmitter, 
            params.underlyingAssetIn, 
            params.underlyingAssetOut, 
            account, 
            amountIn,
            amountOut
        );

    }


    // @notice Validates a swap action.
    // @param amountIn The amount to be swapped in
    function validateSwap(
        address account,
        address dataStore,
        Position.Props memory positionIn,
        Position.Props memory positionOut,
        Pool.Props memory poolIn,
        Pool.Props memory poolOut,
        uint256 amountIn,
        address dex
    ) internal pure {
        Printer.log("-------------------------validateSwap--------------------------");
        if (dex == address(0)){
             revert Errors.SwapPoolsNotMatch(poolIn.underlyingAsset, poolOut.underlyingAsset);
        }

        (   bool isActiveIn,
            bool isFrozenIn, 
            ,
            bool isPausedIn
        ) = poolIn.configuration.getFlags();
        if (!isActiveIn) { revert Errors.PoolIsInactive(poolIn.underlyingAsset); }  
        if (isPausedIn)  { revert Errors.PoolIsPaused(poolIn.underlyingAsset);   }  
        if (isFrozenIn)  { revert Errors.PoolIsFrozen(poolIn.underlyingAsset);   }  

        (   bool isActiveOut,
            bool isFrozenOut, 
            ,
            bool isPausedOut
        ) = poolOut.configuration.getFlags();
        if (!isActiveOut) { revert Errors.PoolIsInactive(poolOut.underlyingAsset); }  
        if (isPausedOut)  { revert Errors.PoolIsPaused(poolOut.underlyingAsset);   }  
        if (isFrozenOut)  { revert Errors.PoolIsFrozen(poolOut.underlyingAsset);   } 

        if(amountIn == 0) {
            revert Errors.EmptySwapAmount();
        } 

        //TODO:healthFactor should be validated        

    }
}
