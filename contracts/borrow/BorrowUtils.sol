// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/DataStore.sol";
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
import "./BorrowEventUtils.sol";

// @title BorrowUtils
// @dev Library for borrow functions, to help with the borrowing of liquidity
// from a pool in return for debt tokens
library BorrowUtils {
    using Pool for Pool.Props;
    using PoolCache for PoolCache.Props;
    using Position for Position.Props;
    using WadRayMath for uint256;

    struct BorrowParams {
        address underlyingAsset;
        uint256 amount;
    }

    struct ExecuteBorrowParams {
        address dataStore;
        address eventEmitter;
        address underlyingAsset;
        uint256 amount;
    }

    struct BorrowLocalVars {
        Pool.Props pool;
        PoolCache.Props poolCache;
        address poolKey;
        bool poolIsUsd;
        IPoolToken poolToken;
        IDebtToken debtToken;
        bytes32 positionKey;
        Position.Props position;
    }

    // @dev executes a borrow
    // @param account the borrowing account
    // @param params ExecuteBorrowParams
    function executeBorrow(address account, ExecuteBorrowParams calldata params) external {
        BorrowLocalVars memory vars;
        (   vars.pool,
            vars.poolCache,
            vars.poolKey,
            vars.poolIsUsd
        ) = PoolUtils.updatePoolAndCache(params.dataStore, params.underlyingAsset);

        (   vars.position,
            vars.positionKey
        ) = PositionUtils.getOrInit(
            account,
            params.dataStore, 
            params.underlyingAsset, 
            Position.PositionTypeNone,
            vars.poolIsUsd
        );

        BorrowUtils.validateBorrow( 
            account, 
            params.dataStore, 
            vars.pool,
            vars.poolCache, 
            params.amount
        );

        //TODO:Should have borrow "to"
        vars.debtToken = IDebtToken(vars.poolCache.debtToken);
        vars.poolToken = IPoolToken(vars.poolCache.poolToken);
        vars.poolToken.addCollateral(account, params.amount);//this line will change Rate
        (, vars.poolCache.nextTotalScaledDebt) = vars.debtToken.mint(
            account, 
            params.amount, 
            vars.poolCache.nextBorrowIndex
        );
        
        vars.position.hasCollateral = true;
        vars.position.hasDebt = true; 
        PositionStoreUtils.set(
            params.dataStore, 
            vars.positionKey, 
            vars.position
        );

        PoolUtils.updateInterestRates(
            params.eventEmitter,
            vars.pool,
            vars.poolCache
        );   

        PoolStoreUtils.set(
            params.dataStore, 
            vars.poolKey, 
            vars.pool
        );

        BorrowEventUtils.emitBorrow(
            params.eventEmitter, 
            params.underlyingAsset, 
            account, 
            params.amount,
            vars.pool.borrowRate,
            vars.poolToken.balanceOfCollateral(account),
            vars.debtToken.scaledBalanceOf(account)            
        );
    }

    // 
    // @dev Validates a borrow action.
    // @param account The borrowing account
    // @param dataStore DataStore
    // @param pool The state of the pool
    // @param poolCache The cached data of the pool
    // @param amountToBorrow The amount to be Borrow
    //
    function validateBorrow(
        address account,
        address dataStore,
        Pool.Props memory pool,
        PoolCache.Props memory poolCache,
        uint256 amountToBorrow
    ) internal view {
        //validate pool configuration
        PoolUtils.validateConfigurationPool(pool, true);   

        if (amountToBorrow == 0) { 
            revert Errors.EmptyBorrowAmounts(); 
        }

        //validate liquidity
        // uint256 unclaimedFee = poolCache.unclaimedFee.rayMul(
        //     poolCache.nextBorrowIndex
        // );
        //uint256 availableLiquidity = IPoolToken(poolCache.poolToken).availableLiquidity(unclaimedFee);
        uint256 availableLiquidity = IPoolToken(poolCache.poolToken).availableLiquidity();
        if(amountToBorrow > availableLiquidity) {
            revert Errors.InsufficientLiquidityForBorrow(amountToBorrow, availableLiquidity);
        }

        //validate pool borrow capacity
        uint256 poolDecimals   = PoolConfigurationUtils.getDecimals(poolCache.configuration);
        uint256 borrowCapacity = PoolConfigurationUtils.getBorrowCapacity(poolCache.configuration) 
                              * (10 ** poolDecimals);

        if (borrowCapacity != 0) {
            uint256 totalDebt =
                poolCache.nextTotalScaledDebt.rayMul(poolCache.nextBorrowIndex) +
                amountToBorrow;
            if (totalDebt > borrowCapacity) {
                revert Errors.BorrowCapacityExceeded(totalDebt, borrowCapacity);
            }
        }

        //validate health
        uint256 configuration = PoolStoreUtils.getConfiguration(dataStore, poolCache.underlyingAsset);
        uint256 decimals = PoolConfigurationUtils.getDecimals(configuration);
        PositionUtils.validateLiquidationHealthFactor(
            account, 
            dataStore, 
            poolCache.underlyingAsset, 
            amountToBorrow,
            decimals
        );

    }
    
}
