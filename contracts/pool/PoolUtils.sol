// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

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
        address underlineTokenAddress;
        address poolToken;
    }


    function updateInterestRates(
        Pool.Props memory pool,
        PoolCache.Props memory poolCache
        address underlineTokenAddress,
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
                underlineTokenAddress: underlineTokenAddress,
                poolToken: reserveCache.poolTokenAddress
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

        poolCache.poolTokenAddress     = pool.poolTokenAddress;
        poolCache.poolDebtTokenAddress = pool.poolDebtTokenAddress;
        poolCache.lastUpdateTimestamp  = pool.lastUpdateTimestamp;

        poolCache.poolConfiguration    = pool.configuration;
        poolCache.feeFactor            = PoolConfigurationUtils.getReserveFactor(poolCache.poolConfigration);

        return poolCache;
    }	

    function updateIndexes(
        Pool.Props memory pool,
        PoolCache.Props memory poolCache
    ) internal {

        if (poolCache.currLiquidityRate != 0) {
            uint256 cumulatedLiquidityInterest = MathUtils.calculateLinearInterest(
              poolCache.currLiquidityRate,
              poolCache.lastUpdateTimestamp
            );
            poolCache.nextLiquidityIndex = cumulatedLiquidityInterest.rayMul(
              poolCache.currLiquidityIndex
            );
            pool.liquidityIndex = poolCache.nextLiquidityIndex.toUint128();
        }

        if (poolCache.currTotalScaledDebt != 0) {
            uint256 cumulatedVariableBorrowInterest = MathUtils.calculateLinearInterest(
              poolCache.currBorrowRate,
              poolCache.lastUpdateTimestamp
            );
            poolCache.nextBorrowIndex = cumulatedVariableBorrowInterest.rayMul(
              poolCache.currBorrowIndex
            );
            pool.borrowIndex = poolCache.nextBorrowIndex.toUint128();
        }

    }

    function updateState(
      Pool.Props memory pool,
      PoolCache.Props memory poolCache
    ) internal {
        uint40 blockTimeStamp = uint40(Chain.currentTimestamp());
        if (reserve.lastUpdateTimestamp == blockTimeStamp) {
           return;
        }
        pool.updateIndexes(poolCache);
        pool.lastUpdateTimestamp = blockTimeStamp;
        //PoolStoreUtils.set(dataStore, poolKey, salt, pool);
    }

    function getPoolNormalizedIncome(
      DataStore dataStore,
      address poolKey,
    ) internal return (uint256) {

        Pool.Props memory pool = PoolStoreUtils.get(dataStore, _poolKey)
        if(pool == null){ revert erros.PoolNotFound(_poolKey); }
        //solium-disable-next-line
        if (pool.lastUpdateTimestamp == block.timestamp) {
            //if the index was updated in the same block, no need to perform any calculation
            return pool.liquidityIndex;
        } else {
            return MathUtils.calculateLinearInterest(pool.LiquidityRate, pool.lastUpdateTimestamp).rayMul(
                     pool.liquidityIndex
                   );
        }
    }

    function getPoolNormalizedDebt(
      DataStore dataStore,
      address poolKey,
    ) internal return (uint256) {

        Pool.Props memory pool = PoolStoreUtils.get(dataStore, _poolKey)
        if(pool == null){ revert erros.PoolNotFound(_poolKey); }
        //solium-disable-next-line
        if (pool.lastUpdateTimestamp == block.timestamp) {
            //if the index was updated in the same block, no need to perform any calculation
            return pool.borrowIndex;
        } else {
            return MathUtils.calculateLinearInterest(pool.borrowRate, pool.lastUpdateTimestamp).rayMul(
                     pool.borrowIndex
                   );
        }
    }

    function getPoolSalt(address underlineTokenAddress) internal view returns (bytes32) {
        bytes32 poolSalt = keccak256(abi.encode(
            "UF_POOL",
            underlineTokenAddress
        )); 
        return  poolSalt;      
    }




}