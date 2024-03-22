// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/DataStore.sol";
import "../error/Errors.sol";

import "../pool/Pool.sol";
import "../pool/PoolCache.sol";
import "../pool/PoolUtils.sol";
import "../pool/PoolStoreUtils.sol";
import "../pool/IPoolToken.sol";


// @title SupplyUtils
// @dev Library for supply functions, to help with the supplying of liquidity
// into a market in return for market tokens
library SupplyUtils {
    using Pool for Pool.Props;
    using PoolCache for PoolCache.Props;

    struct SupplyParams {
        address underlyingAsset;
        address receiver;
    }

    struct ExecuteSupplyParams {
        DataStore dataStore;
        // EventEmitter eventEmitter;
        address underlyingAsset;
        address receiver;

    }

    // @dev executes a supply
    // @param account the supplying account
    // @param params ExecuteSupplyParams
    function executeSupply(
        address account, 
        ExecuteSupplyParams calldata params
    ) external {
        Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, PoolUtils.getKey(params.underlyingAsset));
        PoolUtils.validateEnabledPool(pool, PoolUtils.getKey(params.underlyingAsset));
        Pool.PoolCache memory poolCache = PoolUtils.cache(pool);
        pool.updateStateByIntervalBetweenTransactions(poolCache);

        IPoolToken poolToken = IPoolToken(poolCache.poolToken);
        uint256 supplyAmount = poolToken.recordTransferIn(params.underlyingAsset);

        SupplyUtils.validateSupply(pool, poolCache, supplyAmount);

        pool.updateInterestRates(
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

        //IERC20(underlyingAsset).safeTransferFrom(msg.sender, poolCache.poolToken, params.amount);
        poolToken.mint(
            params.receiver, 
            supplyAmount, 
            poolCache.nextLiquidityIndex
        );
    }

    
    // @dev validates a supply action.
    // @param pool The cached data of the pool
    // @param amount The amount to be supply
    function validateSupply(
        PoolCache.Props memory poolCache,
        uint256 amount
    ) internal view {
        if (amount == 0) { 
            revert Errors.EmptySupplyAmounts(); 
        }

        (
            bool isActive,
            bool isFrozen, 
            bool isPaused,
             , 
         ) = PoolConfigurationUtils.getFlags(poolCache.configuration);
        // require(isActive, Errors.RESERVE_INACTIVE);
        // require(!isPaused, Errors.RESERVE_PAUSED);
        // require(!isFrozen, Errors.RESERVE_FROZEN);

        //uint256 unClaimedFee = FeeUtils.getUnClaimeFee(poolCache);
        uint256 supplyCapacity = PoolConfigurationUtils.getSupplyCapacity(poolCache.configuration)
                                 * (10 ** poolCache.configuration.getDecimals());

        uint256 totalSupplyAddUnclaimedFeeAddAmount = IPoolTaken(poolCache.poolToken).scaledTotalSupply() 
            + poolCache.unclaimedFee.rayMul(poolCache.nextLiquidityIndex) 
            + amount;


        if (supplyCapacity == 0 || totalSupplyAddUnclaimedFeeAddAmount <= supplyCapacity) {
            revert Errors.SupplyCapacityExceeded(totalSupplyAddUnclaimedFeeAddAmount, supplyCapacity);
        }

    }    
    
}
