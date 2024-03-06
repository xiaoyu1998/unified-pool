// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;


// @title WithdrawalUtils
// @dev Library for deposit functions, to help with the depositing of liquidity
// into a market in return for market tokens
library WithdrawalUtils {

    struct WithdrawalParams {
        address poolTokenAddress;
        // address asset;
        uint256 amount;
        address receiver;
    }

    struct ExecuteWithdrawalParams {
        DataStore dataStore;
        address poolTokenAddress;
        // address asset;
        uint256 amount;
        address receiver;
    }

    // @dev executes a deposit
    // @param account the withdrawing account
    // @param params ExecuteWithdrawalParams
    function executeWithdrawal(address account, ExecuteWithdrawalParams calldata params) external {
        Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, params.poolTokenAddress);
        Pool.PoolCache memory poolCache =  PoolUtils.cache(pool);

        PoolUtils.updateIndexesAndIncrementFeeAmount(pool, poolCache);

        IPoolToken poolToken = IPoolToken(poolCache.poolTokenAddress);
        address underlyingTokenAddress = poolToken.underlyingTokenAddress();
        
        uint256 userBalance = poolToken.scaledBalanceOf(account).rayMul(poolCache.nextLiquidityIndex);
        uint256 amountToWithdrawal = params.amount;
        if (params.amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }

        ExecuteWithdrawalUtils.validateWithdrawal(poolCache, amountToWithdrawal, userBalance)
        PoolUtils.updateInterestRates(pool, poolCache, underlyingTokenAddress, 0, amountToWithdrawal);
        PoolStoreUtils.set(params.dataStore, params.poolTokenAddress, PoolUtils.getPoolSalt(underlyingTokenAddress));

        poolToken.burn(params.receiver, amountToWithdrawal, poolCache.nextLiquidityIndex)
    }


      /**
       * @notice Validates a withdraw action.
       * @param poolCache The cached data of the pool
       * @param amount The amount to be withdrawn
       * @param userBalance The balance of the user
       */
      function validateWithdrawal(
          PoolCache.Props memory poolCache,
          uint256 amount,
          uint256 userBalance
      ) internal pure {
          require(amount != 0, Errors.INVALID_AMOUNT);
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
