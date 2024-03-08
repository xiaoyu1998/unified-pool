// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "./Pool.sol";
import "./PoolCache.sol";
import "./PoolConfigurationUtils.sol";


// @title PoolUtils
// @dev Library for Pool functions
library PoolUtils {
    using Pool for Pool.Props;
    using PoolCache for PoolCache.Props;

    struct UpdateInterestRatesLocalVars {
        uint256 nextLiquidityRate;
        uint256 nextBorrowRate;
        uint256 totalDebt;
    }


    struct CalculateInterestRatesParams {
        uint256 liquidityIn;
        uint256 liquidityOut;
        uint256 totalDebt;
        uint256 feeFactor;
        address underlineToken;
        address poolToken;
    }

    function updateInterestRates(
        Pool.Props memory pool,
        PoolCache.Props memory poolCache
        address underlineToken,
        uint256 liquidityIn,
        uint256 liquidityOut
    ) internal {
        UpdateInterestRatesLocalVars memory vars;

        vars.totalDebt = poolCache.nextTotalScaledDebt.rayMul(
           poolCache.nextBorrowIndex
        );

        (
            vars.nextLiquidityRate,
            vars.nextBorrowRate
        ) = IPoolInterestRateStrategy(pool.interestRateStrategyAddress).calculateInterestRates(
            CalculateInterestRatesParams({
                liquidityIn: liquidityIn,
                liquidityOut: liquidityOut,
                totalDebt: vars.totalDebt,
                feeFactor: poolCache.feeFactor,
                underlineToken: underlineToken,
                poolToken: reserveCache.poolToken
            })
        );

        pool.LiquidityRate = vars.nextLiquidityRate.toUint128();
        pool.borrowRate = vars.nextBorrowRate.toUint128();

    }


    function cache(
      Pool.Props memory pool
    ) internal view returns (PoolCache.Props memory) {
        PoolCache.Props memory poolCache;

        poolCache.currLiquidityIndex = poolCache.nextLiquidityIndex = pool.liquidityIndex;
        poolCache.currLiquidityRate  = pool.LiquidityRate;
        poolCache.currBorrowIndex    = poolCache.nextBorrowIndex    = pool.borrowIndex;
        poolCache.currBorrowRate     = pool.borrowRate;

        poolCache.currTotalScaledDebt = poolCache.nextTotalScaledDebt = IDebtToken(
            poolCache.poolDebtTokenAddress
        ).scaledTotalSupply();

        poolCache.poolToken     = pool.poolToken;
        poolCache.DebtToken     = pool.DebtToken;
        poolCache.lastUpdateTimestamp  = pool.lastUpdateTimestamp;

        poolCache.poolConfiguration    = pool.configuration;
        //poolCache.feeFactor            = PoolConfigurationUtils.getReserveFactor(poolCache.poolConfigration);

        return poolCache;
    }	

    function updateIndexes(
        Pool.Props memory pool,
        PoolCache.Props memory poolCache
    ) internal {
        if (poolCache.currLiquidityRate != 0) {
            uint256 cumulatedLiquidityInterest = MathUtils.calculateInterest(
                poolCache.currLiquidityRate,
                poolCache.lastUpdateTimestamp
            );
            poolCache.nextLiquidityIndex = cumulatedLiquidityInterest.rayMul(
                poolCache.currLiquidityIndex
            );
            pool.setLiquidityIndex(poolCache.nextLiquidityIndex);
        }

        if (poolCache.currTotalScaledDebt != 0) {
            uint256 cumulatedVariableBorrowInterest = MathUtils.calculateInterest(
                poolCache.currBorrowRate,
                poolCache.lastUpdateTimestamp
            );
            poolCache.nextBorrowIndex = cumulatedVariableBorrowInterest.rayMul(
                poolCache.currBorrowIndex
            );
            pool.setBorrowIndex(poolCache.nextBorrowIndex;
        }
    }

    function updateStateIntervalTwoTransactions(
      Pool.Props memory pool,
      PoolCache.Props memory poolCache
    ) internal {
        uint256 blockTimeStamp = Chain.currentTimestamp();
        if (poolCache.lastUpdateTimestamp == blockTimeStamp) {
           return;
        }
        pool.updateIndexes(poolCache);
        pool.incrementClaimableFeeAmount(poolCache);
        pool.setLastUpdateTimestamp(blockTimeStamp);
    }

    function getPoolNormalizedLiquidityIndex(
      DataStore dataStore,
      address poolKey,
    ) internal return (uint256) {
        Pool.Props memory pool = PoolStoreUtils.get(dataStore, poolKey)
        validateEnabledPool(pool)

        if (pool.lastUpdateTimestamp() == block.timestamp) {
            return pool.liquidityIndex();
        } else {
            uint256 periodicAnnualizedIncomeInterest = MathUtils.calculateInterest(
                pool.LiquidityRate(), 
                pool.lastUpdateTimestamp()
            )
            return periodicAnnualizedIncomeInterest.rayMul(pool.liquidityIndex());
        }
    }

    function getPoolNormalizedBorrowingIndex(
      DataStore dataStore,
      address poolKey,
    ) internal return (uint256) {
        Pool.Props memory pool = PoolStoreUtils.get(dataStore, poolKey)
        validateEnabledPool(pool)

        if (pool.lastUpdateTimestamp() == block.timestamp) {
            return pool.borrowIndex();
        } else {
            uint256 periodicAnnualizedBorrowInterest = MathUtils.calculateInterest(
                pool.borrowRate(), 
                pool.lastUpdateTimestamp()
            )
            return periodicAnnualizedBorrowInterest.rayMul(pool.borrowIndex());
        }
    }

    function getPoolSalt(address underlineTokenAddress) internal view returns (bytes32) {
        bytes32 poolSalt = keccak256(abi.encode("UF_POOL", underlineTokenAddress)); 
        return  poolSalt;      
    }

    function getPoolKey(address poolToken) internal pure returns (bytes32) {
        bytes32 key = keccak256(abi.encode(poolToken));
        return key;
    }

    function validateEnabledPool(Pool.Props memory pool) internal view {
        if (pool.poolTokenAddress() == address(0)) {
            revert Errors.EmptyPool();
        }

    }


}