// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;


// @title BorrowUtils
// @dev Library for deposit functions, to help with the depositing of liquidity
// into a market in return for market tokens
library BorrowUtils {

    struct BorrowParams {
        address collateralPoolTokenAddress;
        address borrowPoolTokenAddress;
        uint256 amountToBorrow;
    }

    struct ExecuteBorrowParams {
        DataStore dataStore;
        address collateralPoolTokenAddress;
        address borrowPoolTokenAddress;
        uint256 amountToBorrow;
    }

    // @dev executes a deposit
    // @param account the withdrawing account
    // @param params ExecuteBorrowParams
    function executeBorrow(address account, ExecuteBorrowParams calldata params) external {

        Position.Props memory position = PoolStoreUtils.get(params.dataStore, account);
        if(position == null){
            position = PositionFactory.createPostion(account);
        }

        //add collateral
        IPoolToken collateralPoolToken = IPoolToken(params.collateralPoolTokenAddress);
        address underlyingTokenAddress = collateralPoolToken.underlyingTokenAddress();
        uint256 collateralAmount = collateralPoolToken.recordTransferIn(underlyingTokenAddress);
        if(collateralAmount > 0)}{
            collateralPoolToken.addCollateral(collateralAmount);
            PositionUtils.addCollateral(position, account, params.collateralPoolTokenAddress, collateralAmount)
        }

        if(amountToBorrow > 0){
            Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, params.borrowPoolTokenAddress);
            Pool.PoolCache memory poolCache =  PoolUtils.cache(pool);

            PoolUtils.updateIndexesAndIncrementFeeAmount(pool, poolCache);

            ExecuteBorrowUtils.validateBorrow(poolCache, position, amountToBorrow)
            IPoolToken borrowPoolToken = IPoolToken(params.borrowPoolTokenAddress);
            borrowPoolToken.addCollateral(borrowPoolToken);
            PositionUtils.addCollateral(position, account, params.borrowPoolTokenAddress, borrowPoolToken)

            poolCache.nextScaledDebt = IDebtToken(poolCache.debtTokenAddress)
            .mint(account, params.amount, poolCache.nextBorrowIndex);
            
            PoolUtils.updateInterestRates(pool, poolCache, params.asset, 0, amountToBorrow);
            PoolStoreUtils.set(params.dataStore, params.borrowPoolTokenAddress, PoolUtils.getPoolSalt(params.asset), pool);
        }

        //IPoolToken(poolCache.poolTokenAddress).burn(params.receiver, amountToBorrow, poolCache.nextLiquidityIndex)
    }


      /**
       * @notice Validates a withdraw action.
       * @param poolCache The cached data of the pool
       * @param amount The amount to be withdrawn
       * @param userBalance The balance of the user
       */
      function validateBorrow(
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
