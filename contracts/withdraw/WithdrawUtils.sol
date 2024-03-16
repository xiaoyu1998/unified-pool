// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;


// @title WithdrawUtils
// @dev Library for withdraw functions, to help with the withdrawing of liquidity
// into a market in return for market tokens
library WithdrawUtils {

    struct WithdrawParams {
        address underlyingAsset;
        uint256 amount;
        address to;
    }

    struct ExecuteWithdrawParams {
        DataStore dataStore;
        address underlyingAsset;
        uint256 amount;
        address to;
    }

    // @dev executes a widthdraw
    // @param account the withdrawing account
    // @param params ExecuteWithdrawParams
    function executeWithdraw(address account, ExecuteWithdrawParams calldata params) external {
        Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, params.underlyingAsset);
        PoolUtils.validateEnabledPool(pool);
        Pool.PoolCache memory poolCache =  PoolUtils.cache(pool);
        pool.updateStateByIntervalBetweenTransactions(pool, poolCache);

        IPoolToken poolToken = IPoolToken(poolCache.poolToken);
        uint256 userBalance = poolToken.scaledBalanceOf(account).rayMul(poolCache.nextLiquidityIndex);
        uint256 amountToWithdraw = params.amount;
        if (params.amount == (uint256).max) { //withdraw user balance
            amountToWithdraw = userBalance;
        }

        WithdrawUtils.validateWithdraw(poolCache, amountToWithdraw, userBalance)

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

        poolToken.burn(params.to, amountToWithdraw, poolCache.nextLiquidityIndex)
    }


      /**
       * @notice Validates a withdraw action.
       * @param poolCache The cached data of the pool
       * @param amount The amount to be withdrawn
       * @param userBalance The balance of the user
       */
      function validateWithdraw(
          PoolCache.Props memory poolCache,
          uint256 amount,
          uint256 userBalance
      ) internal pure {
          if (amount == 0) { revert Errors.EmptyWithdrawAmount() }
          require(amount <= userBalance, Errors.NOT_ENOUGH_AVAILABLE_USER_BALANCE);

          (bool isActive, , , bool isPaused) = poolCache.poolConfiguration.getFlags();
          require(isActive, Errors.RESERVE_INACTIVE);
          require(!isPaused, Errors.RESERVE_PAUSED);

          //TODO should check the underlying token balance is sufficient to this withdraw
          // uint256 availableBalance = IPoolToken(poolCache.poolTokenAddress)
          //                                .totalUnderlyingTokenBalanceDeductCollateral()
          // require(amount < availableBalance, 
          //         Errors.InsufficientBalanceAfterSubstractionCollateral(amount, availableBalance));
      }
    
}
