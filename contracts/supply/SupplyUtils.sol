// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/DataStore.sol";
import "../data/Keys.sol";
import "../error/Errors.sol";

import "../pool/Pool.sol";
import "../pool/PoolCache.sol";
import "../pool/PoolUtils.sol";
import "../pool/PoolStoreUtils.sol";
import "../token/IPoolToken.sol";

import "../event/EventEmitter.sol";
import "./SupplyEventUtils.sol";


import "../utils/Printer.sol";


// @title SupplyUtils
// @dev Library for supply functions, to help with the supplying of liquidity
// into a market in return for market tokens
library SupplyUtils {
    using Pool for Pool.Props;
    using PoolCache for PoolCache.Props;
    using WadRayMath for uint256;
    using PoolConfigurationUtils for uint256;

    struct SupplyParams {
        address underlyingAsset;
        address to;
    }

    struct ExecuteSupplyParams {
        address dataStore;
        address eventEmitter;
        address underlyingAsset;
        address to;
    }

    // @dev executes a supply
    // @param account the supplying account
    // @param params ExecuteSupplyParams
    function executeSupply(
        address account, 
        ExecuteSupplyParams calldata params
    ) external {
        address poolKey = Keys.poolKey(params.underlyingAsset);
        Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, poolKey);
        PoolUtils.validateEnabledPool(pool, poolKey);
        PoolCache.Props memory poolCache = PoolUtils.cache(pool);
        PoolUtils.updateStateBetweenTransactions(pool, poolCache);

        IPoolToken poolToken = IPoolToken(poolCache.poolToken);
        uint256 supplyAmount = poolToken.recordTransferIn(params.underlyingAsset);


        SupplyUtils.validateSupply(
            poolCache, 
            supplyAmount
        );

        PoolUtils.updateInterestRates(
            pool,
            poolCache, 
            params.underlyingAsset, 
            supplyAmount, 
            0
        );

        PoolStoreUtils.set(
            params.dataStore, 
            params.underlyingAsset, 
            pool
        );

        poolToken.mint(
            params.to, 
            supplyAmount, 
            poolCache.nextLiquidityIndex
        );

        SupplyEventUtils.emitSupply(
            params.eventEmitter, 
            params.underlyingAsset, 
            account, 
            params.to, 
            supplyAmount
        );
    }

    
    // @dev validates a supply action.
    // @param pool The cached data of the pool
    // @param amount The amount to be supply
    function validateSupply(
        PoolCache.Props memory poolCache,
        uint256 amount
    ) internal view {
        (   bool isActive,
            bool isFrozen, 
            ,
            bool isPaused
         ) = poolCache.configuration.getFlags();
        if (!isActive) { revert Errors.PoolIsInactive(poolCache.underlyingAsset); }  
        if (isPaused)  { revert Errors.PoolIsPaused(poolCache.underlyingAsset);   }  
        if (isFrozen)  { revert Errors.PoolIsFrozen(poolCache.underlyingAsset);   } 

        if (amount == 0) { 
            revert Errors.EmptySupplyAmounts(); 
        }  

        uint256 supplyCapacity = poolCache.configuration.getSupplyCapacity()
                                 * (10 ** poolCache.configuration.getDecimals());

        uint256 totalSupplyAddUnclaimedFeeAddSupplyAmount = 
            (IPoolToken(poolCache.poolToken).scaledTotalSupply() + poolCache.unclaimedFee)
            .rayMul(poolCache.nextLiquidityIndex) + amount;

        if (supplyCapacity == 0 || totalSupplyAddUnclaimedFeeAddSupplyAmount > supplyCapacity) {
            revert Errors.SupplyCapacityExceeded(totalSupplyAddUnclaimedFeeAddSupplyAmount, supplyCapacity);
        }

    }    
    
}
