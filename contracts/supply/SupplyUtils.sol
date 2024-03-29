// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/DataStore.sol";
import "../error/Errors.sol";

import "../pool/Pool.sol";
import "../pool/PoolCache.sol";
import "../pool/PoolUtils.sol";
import "../pool/PoolStoreUtils.sol";
import "../token/IPoolToken.sol";

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
        DataStore dataStore;
        // EventEmitter eventEmitter;
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
        Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, PoolUtils.getKey(params.underlyingAsset));
        PoolUtils.validateEnabledPool(pool, PoolUtils.getKey(params.underlyingAsset));
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

        //IERC20(underlyingAsset).safeTransferFrom(msg.sender, poolCache.poolToken, params.amount);
        poolToken.mint(
            params.to, 
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
         ) = poolCache.configuration.getFlags();
        if (!isActive) { revert Errors.PoolIsInactive(); }  
        if (isPaused)  { revert Errors.PoolIsPaused();   }  
        if (isFrozen)  { revert Errors.PoolIsFrozen();   }   

        //uint256 unClaimedFee = FeeUtils.getUnClaimeFee(poolCache);
        uint256 supplyCapacity = poolCache.configuration.getSupplyCapacity()
                                 * (10 ** poolCache.configuration.getDecimals());

        // Printer.log("SupplyCapacity", poolCache.configuration.getSupplyCapacity());
        // Printer.log("Decimals", poolCache.configuration.getDecimals());
        // Printer.log("SupplyCapacity", supplyCapacity);

        uint256 totalSupplyAddUnclaimedFeeAddAmount = 
            (IPoolToken(poolCache.poolToken).scaledTotalSupply() + poolCache.unclaimedFee)
            .rayMul(poolCache.nextLiquidityIndex) + amount;


        if (supplyCapacity == 0 || totalSupplyAddUnclaimedFeeAddAmount > supplyCapacity) {
            revert Errors.SupplyCapacityExceeded(totalSupplyAddUnclaimedFeeAddAmount, supplyCapacity);
        }

    }    
    
}
