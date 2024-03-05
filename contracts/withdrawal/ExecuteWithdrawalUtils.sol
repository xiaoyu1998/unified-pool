// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;


// @title WithdrawalUtils
// @dev Library for deposit functions, to help with the depositing of liquidity
// into a market in return for market tokens
library ExecuteWithdrawalUtils {

    struct WithdrawalParams {
        address poolTokenAddress;
        address asset;
        uint256 amount;
        address receiver;
    }

    struct ExecuteWithdrawalParams {
        DataStore dataStore;
        address poolTokenAddress;
        address asset;
        uint256 amount;
        address receiver;

    }

    // @dev executes a deposit
    // @param params ExecuteWithdrawalParams
    function executeWithdrawal(address account, ExecuteWithdrawalParams calldata params) external {
        Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, params.poolTokenAddress);
        Pool.PoolCache memory poolCache =  PoolUtils.cache(pool);

        PoolUtils.updateState(pool, poolCache);

        uint256 userBalance = IPoolToken(poolCache.poolTokenAddress).scaledBalanceOf(account).rayMul(
            poolCache.nextLiquidityIndex
        );

        uint256 amountToWithdrawal = params.amount;
        if (params.amount == type(uint256).max) {
          amountToWithdraw = userBalance;
        }

        ExecuteWithdrawalUtils.validateWithdrawal(poolCache, pool, amountToWithdrawal, userBalance)
        PoolUtils.updateInterestRates(pool, poolCache, params.asset, 0, amountToWithdrawal);
        PoolStoreUtils.set(params.dataStore, params.poolTokenAddress, PoolUtils.getPoolSalt(params.asset), pool);

        IPoolToken(poolCache.poolTokenAddress).burn(params.receiver, amountToWithdrawal, poolCache.nextLiquidityIndex)
    }

    
}
