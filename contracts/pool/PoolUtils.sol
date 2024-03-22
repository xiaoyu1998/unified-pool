// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/DataStore.sol";
import "../error/Errors.sol";

import "./Pool.sol";
import "./PoolCache.sol";
import "./PoolConfigurationUtils.sol";
import "./PoolStoreUtils.sol";
import "../token/IPoolToken.sol";
import "../token/IDebtToken.sol";

import "../interest/InterestUtils.sol";
import "../interest/IPoolInterestRateStrategy.sol";

import "../chain/Chain.sol";
import "../fee/FeeUtils.sol";

import "../utils/WadRayMath.sol";


// @title PoolUtils
// @dev Library for Pool functions
library PoolUtils {
    using Pool for Pool.Props;
    using PoolCache for PoolCache.Props;
    using WadRayMath for uint256;

    struct UpdateInterestRatesLocalVars {
        uint256 nextLiquidityRate;
        uint256 nextBorrowRate;
        uint256 totalDebt;
    }
    
    function updateInterestRates(
        Pool.Props memory pool,
        PoolCache.Props memory poolCache,
        address underlyingAsset,
        uint256 liquidityIn,
        uint256 liquidityOut
    ) internal {

        UpdateInterestRatesLocalVars memory vars;

        vars.totalDebt = poolCache.nextTotalScaledDebt.rayMul(
            poolCache.nextBorrowIndex
        );

        (   vars.nextLiquidityRate,
            vars.nextBorrowRate
        ) = IPoolInterestRateStrategy(pool.interestRateStrategy).calculateInterestRates(
            InterestUtils.CalculateInterestRatesParams(
                liquidityIn,
                liquidityOut,
                vars.totalDebt,
                poolCache.feeFactor,
                underlyingAsset,
                poolCache.poolToken
            )
        );

        pool.liquidityRate = vars.nextLiquidityRate;
        pool.borrowRate    = vars.nextBorrowRate;
    }

    function cache(
      Pool.Props memory pool
    ) internal view returns (PoolCache.Props memory) {
        PoolCache.Props memory poolCache;

        poolCache.currLiquidityIndex = poolCache.nextLiquidityIndex = pool.liquidityIndex;
        poolCache.currLiquidityRate  = pool.liquidityRate;
        poolCache.currBorrowIndex    = poolCache.nextBorrowIndex    = pool.borrowIndex;
        poolCache.currBorrowRate     = pool.borrowRate;

        poolCache.currTotalScaledDebt = poolCache.nextTotalScaledDebt = IDebtToken(
            poolCache.debtToken
        ).scaledTotalSupply();

        poolCache.poolToken     = pool.poolToken;
        poolCache.DebtToken     = pool.debtToken;

        poolCache.poolConfiguration   = pool.configuration;
        poolCache.feeFactor           = PoolConfigurationUtils.getReserveFactor(poolCache.configration);
        poolCache.totalFee            = pool.totalFee;
        poolCache.unclaimedFee        = pool.unclaimedFee;
        poolCache.lastUpdateTimestamp = pool.lastUpdateTimestamp;

        return poolCache;
    }	

    function updateIndexes(
        Pool.Props memory pool,
        PoolCache.Props memory poolCache
    ) internal {
        if (poolCache.currLiquidityRate != 0) {
            uint256 cumulatedLiquidityInterest = InterestUtils.calculateInterest(
                poolCache.currLiquidityRate,
                poolCache.lastUpdateTimestamp
            );
            poolCache.nextLiquidityIndex = cumulatedLiquidityInterest.rayMul(
                poolCache.currLiquidityIndex
            );
            pool.liquidityIndex = poolCache.nextLiquidityIndex;
        }

        if (poolCache.currTotalScaledDebt != 0) {
            uint256 cumulatedBorrowInterest = InterestUtils.calculateInterest(
                poolCache.currBorrowRate,
                poolCache.lastUpdateTimestamp
            );
            poolCache.nextBorrowIndex = cumulatedBorrowInterest.rayMul(
                poolCache.currBorrowIndex
            );
            pool.borrowIndex = poolCache.nextBorrowIndex;
        }
    }

    function updateStateByIntervalBetweenTransactions(
      Pool.Props memory pool,
      PoolCache.Props memory poolCache
    ) internal {
        uint256 blockTimeStamp = Chain.currentTimestamp();
        if (poolCache.lastUpdateTimestamp == blockTimeStamp) {
            return;
        }
        pool.updateIndexes(poolCache);
        FeeUtils.incrementClaimableFeeAmount(pool, poolCache);
        pool.lastUpdateTimestamp = blockTimeStamp;
    }

    function getPoolNormalizedLiquidityIndex(
      DataStore dataStore,
      address key
    ) internal returns (uint256) {
        Pool.Props memory pool = PoolStoreUtils.get(dataStore, key);
        validateEnabledPool(pool, key);

        if (pool.lastUpdateTimestamp == Chain.currentTimestamp()) {
            return pool.liquidityIndex;
        } else {
            uint256 periodicIncomeInterest = InterestUtils.calculateInterest(
                pool.LiquidityRate, 
                pool.lastUpdateTimestamp
            );
            return periodicIncomeInterest.rayMul(pool.liquidityIndex);
        }
    }

    function getPoolNormalizedBorrowingIndex(
      DataStore dataStore,
      address key
    ) internal returns (uint256) {
        Pool.Props memory pool = PoolStoreUtils.get(dataStore, key);
        validateEnabledPool(pool, key);

        if (pool.lastUpdateTimestamp == block.timestamp) {
            return pool.borrowIndex;
        } else {
            uint256 periodicBorrowInterest = InterestUtils.calculateInterest(
                pool.borrowRate, 
                pool.lastUpdateTimestamp
            );
            return periodicBorrowInterest.rayMul(pool.borrowIndex);
        }
    }

    function getKey(
        address underlyingAsset
    ) internal pure returns (address) {
        // bytes32 key = keccak256(abi.encode(underlyingAsset));
        // return key;
        return underlyingAsset;
    }

    function validateEnabledPool(
        Pool.Props memory pool,
        address key
    ) internal view {
        if (pool.poolToken == address(0)) {
            revert Errors.PoolNotFound(key);
        }

    }


}