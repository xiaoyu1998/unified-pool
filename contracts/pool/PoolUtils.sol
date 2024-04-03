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

import "../utils/Printer.sol";
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
        Printer.log("--------------------updateInterestRates---------------------3");

        UpdateInterestRatesLocalVars memory vars;
        vars.totalDebt = poolCache.nextTotalScaledDebt.rayMul(
            poolCache.nextBorrowIndex
        );

        Printer.log("liquidityIn", liquidityIn);
        Printer.log("liquidityOut", liquidityOut);
        Printer.log("nextTotalScaledDebt", poolCache.nextTotalScaledDebt);
        Printer.log("nextBorrowIndex", poolCache.nextBorrowIndex);
        Printer.log("totalDebt", vars.totalDebt);
        Printer.log("feeFactor", poolCache.feeFactor); 

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
  
        Printer.log("liquidityRate", pool.liquidityRate);   
        Printer.log("borrowRate", pool.borrowRate);   

    }

    function cache(
      Pool.Props memory pool
    ) internal view returns (PoolCache.Props memory) {
        PoolCache.Props memory poolCache;

        poolCache.currLiquidityIndex = poolCache.nextLiquidityIndex = pool.liquidityIndex;
        poolCache.currLiquidityRate  = pool.liquidityRate;
        poolCache.currBorrowIndex    = poolCache.nextBorrowIndex    = pool.borrowIndex;
        poolCache.currBorrowRate     = pool.borrowRate;

        poolCache.underlyingAsset = pool.underlyingAsset;
        poolCache.poolToken       = pool.poolToken;
        poolCache.debtToken       = pool.debtToken;

        poolCache.currTotalScaledDebt = poolCache.nextTotalScaledDebt = IDebtToken(
            poolCache.debtToken
        ).scaledTotalSupply();

        poolCache.configuration = pool.configuration;
        poolCache.feeFactor     = PoolConfigurationUtils.getFeeFactor(poolCache.configuration);
        poolCache.totalFee      = pool.totalFee;
        poolCache.unclaimedFee  = pool.unclaimedFee;
        poolCache.lastUpdateTimestamp = pool.lastUpdateTimestamp;

        Printer.log("-------------------------cachepool--------------------------1");
        Printer.log("currLiquidityIndex", poolCache.currLiquidityIndex);
        Printer.log("nextLiquidityIndex", poolCache.nextLiquidityIndex);
        Printer.log("currLiquidityRate", poolCache.currLiquidityRate);
        Printer.log("currBorrowIndex", poolCache.currBorrowIndex);
        Printer.log("nextBorrowIndex", poolCache.nextBorrowIndex);
        Printer.log("currBorrowRate", poolCache.currBorrowRate);
        Printer.log("underlyingAsset", poolCache.underlyingAsset);
        Printer.log("poolToken", poolCache.poolToken);
        Printer.log("debtToken", poolCache.debtToken);
        Printer.log("currTotalScaledDebt", poolCache.currTotalScaledDebt);
        Printer.log("nextTotalScaledDebt", poolCache.nextTotalScaledDebt);
        Printer.log("configuration", poolCache.configuration); 
        Printer.log("feeFactor", poolCache.feeFactor);   
        Printer.log("totalFee", poolCache.totalFee);   
        Printer.log("unclaimedFee", poolCache.unclaimedFee);   
        Printer.log("lastUpdateTimestamp", poolCache.lastUpdateTimestamp);   

        return poolCache;
    }	

    function updateIndexes(
        Pool.Props memory pool,
        PoolCache.Props memory poolCache
    ) internal {
        Printer.log("-----------------------updateIndexes------------------------2");
        if (poolCache.currLiquidityRate != 0) {
            uint256 cumulatedLiquidityInterest = InterestUtils.calculateInterest(
                poolCache.currLiquidityRate,
                poolCache.lastUpdateTimestamp
            );
            poolCache.nextLiquidityIndex = cumulatedLiquidityInterest.rayMul(
                poolCache.currLiquidityIndex
            );
            pool.liquidityIndex = poolCache.nextLiquidityIndex;

            Printer.log("currLiquidityRate", poolCache.currLiquidityRate);
            Printer.log("cumulatedLiquidityInterest", cumulatedLiquidityInterest);
            Printer.log("currLiquidityIndex", poolCache.currLiquidityIndex);
            Printer.log("liquidityIndex", pool.liquidityIndex);
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

            Printer.log("currBorrowRate", poolCache.currBorrowRate);
            Printer.log("cumulatedBorrowInterest", cumulatedBorrowInterest);
            Printer.log("currBorrowIndex", poolCache.currBorrowIndex);
            Printer.log("borrowIndex", pool.borrowIndex);

        }
   
    }

    function updateStateBetweenTransactions(
      Pool.Props memory pool,
      PoolCache.Props memory poolCache
    ) internal {
        uint256 blockTimeStamp = Chain.currentTimestamp();
        if (poolCache.lastUpdateTimestamp == blockTimeStamp) {
            return;
        }
        updateIndexes(pool, poolCache);
        FeeUtils.incrementFeeAmount(pool, poolCache);
        pool.lastUpdateTimestamp = blockTimeStamp;
    }

    function getPoolNormalizedLiquidityIndex(
      DataStore dataStore,
      address key
    ) internal view returns (uint256) {
        Pool.Props memory pool = PoolStoreUtils.get(dataStore, key);
        validateEnabledPool(pool, key);

        if (pool.lastUpdateTimestamp == Chain.currentTimestamp()) {
            return pool.liquidityIndex;
        } else {
            uint256 periodicIncomeInterest = InterestUtils.calculateInterest(
                pool.liquidityRate, 
                pool.lastUpdateTimestamp
            );
            return periodicIncomeInterest.rayMul(pool.liquidityIndex);
        }
    }

    function getPoolNormalizedBorrowingIndex(
      DataStore dataStore,
      address key
    ) internal view  returns (uint256) {
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
    ) internal pure {
        if (pool.poolToken == address(0)) {
            revert Errors.PoolNotFound(key);
        }

    }


}