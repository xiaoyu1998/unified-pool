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
// import "./SwapEventUtils.sol";

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
        //address to;
    }

    struct ExecuteSwapParams {
        address dataStore;
        address eventEmitter;
        address underlyingAssetIn;
        address underlyingAssetOut;
        uint256 amountIn;
        uint256 sqrtPriceLimitX96;
        //address to;
    }

    // @dev executes a swap
    // @param account the swapng account
    // @param params ExecuteSwapParams
    function executeSwap(
        address account, 
        ExecuteSwapParams calldata params
    ) external {
        Printer.log("-------------------------executeSwap--------------------------");
        //TODO:should be just get the pooltoken and pool configuration only
        address poolKeyIn = Keys.poolKey(params.underlyingAssetIn);
        Pool.Props memory poolIn = PoolStoreUtils.get(params.dataStore, poolKeyIn);
        PoolUtils.validateEnabledPool(poolIn, poolKeyIn);
        // PoolCache.Props memory poolCacheIn = PoolUtils.cache(poolIn);
        // PoolUtils.updateStateBetweenTransactions(poolIn, poolCacheIn);
        bytes32 positionKeyIn = Keys.accountPositionKey(params.underlyingAssetIn, account);
        Position.Props memory positionIn  = PositionStoreUtils.get(params.dataStore, positionKeyIn);

        address poolKeyOut = Keys.poolKey(params.underlyingAssetOut);
        Pool.Props memory poolOut = PoolStoreUtils.get(params.dataStore, poolKeyOut);
        PoolUtils.validateEnabledPool(poolOut, poolKeyOut);

        bool poolOutIsUsd = PoolConfigurationUtils.getUsd(poolOut.configuration);
        // PoolCache.Props memory poolCacheOut = PoolUtils.cache(poolOut);
        // PoolUtils.updateStateBetweenTransactions(poolOut, poolCacheOut);
        bytes32 positionKeyOut = Keys.accountPositionKey(params.underlyingAssetOut, account);
        Position.Props memory positionOut  = PositionStoreUtils.get(params.dataStore, positionKeyOut);
        if(positionOut.account == address(0)){
            positionOut.account = account;
            positionOut.underlyingAsset = params.underlyingAssetOut;
            positionOut.positionType = Position.PositionTypeNone;
            positionOut.hasCollateral = true;
            positionOut.hasDebt = false;
            if (!poolOutIsUsd) {
                positionOut.positionType = Position.PositionTypeLong;
            }
        }

        bool isLong = true;
        if (poolOutIsUsd) {
            isLong = false;
        }
        
        address dex = DexStoreUtils.get(params.dataStore, params.underlyingAssetIn, params.underlyingAssetOut);

        SwapUtils.validateSwap( 
            account, 
            params.dataStore, 
            positionIn, 
            positionOut, 
            poolIn, 
            poolOut,
            params.amountIn,
            dex
        );

        IPoolToken poolTokenIn  = IPoolToken(poolIn.poolToken);
        IPoolToken poolTokenOut  = IPoolToken(poolOut.poolToken);
        poolTokenIn.approveLiquidity(dex, params.amountIn);

        IDex(dex).swap(
            address(poolTokenIn), 
            params.underlyingAssetIn, 
            params.amountIn, 
            address(poolTokenOut), 
            uint160(params.sqrtPriceLimitX96)
        );

        uint256 amountOut = poolTokenOut.recordTransferIn(params.underlyingAssetOut);
        
        poolTokenIn.removeCollateral(account, params.amountIn);//this line will assert if account InsufficientCollateralAmount
        poolTokenOut.addCollateral(account, amountOut);

        uint256 price = OracleUtils.calcPrice(
            params.amountIn,
            PoolConfigurationUtils.getDecimals(poolIn.configuration), 
            amountOut,
            PoolConfigurationUtils.getDecimals(poolOut.configuration),
            poolOutIsUsd
        );

        if (isLong) {
            PositionUtils.UpdateEntryLongPrice(positionOut, price, amountOut);
        } else {
            PositionUtils.UpdateEntryShortPrice(positionIn,  price, params.amountIn);
        }

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
        //     params.underlyingAssetIn, 
        //     0, 
        //     0 
        // );
        // PoolStoreUtils.set(
        //     params.dataStore, 
        //     params.underlyingAssetIn, 
        //     poolIn
        // );

        // PoolUtils.updateInterestRates(
        //     poolOut,
        //     poolCacheOut, 
        //     params.underlyingAssetOut, 
        //     0, 
        //     0 
        // );
        // PoolStoreUtils.set(
        //     params.dataStore, 
        //     params.underlyingAssetOut, 
        //     poolOut
        // );

    }


    // @notice Validates a swap action.
    // @param amountIn The amount to be swap in
    function validateSwap(
        address account,
        address dataStore,
        Position.Props memory positionIn,
        Position.Props memory positionOut,
        Pool.Props memory poolIn,
        Pool.Props memory poolOut,
        uint256 amountIn,
        address dex
    ) internal view {
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


        //  bool poolOutIsUsd = PoolConfigurationUtils.getUsd(poolOut.configuration);
        //  bool poolInIsUsd = PoolConfigurationUtils.getUsd(poolIn.configuration);
        // if ((poolOutIsUsd && poolInIsUsd) || (!poolOutIsUsd && !poolInIsUsd) ) {
        //     revert Errors.SwapPoolsNotMatch(poolIn.underlyingAsset, poolOut.underlyingAsset);
        // }

        if(amountIn == 0) {
            revert Errors.EmptySwapAmount();
        }        

    }
}
