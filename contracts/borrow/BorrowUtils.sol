// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;


// @title BorrowUtils
// @dev Library for borrow functions, to help with the borrowing of liquidity
// into a market in return for market tokens
library BorrowUtils {

    struct BorrowParams {
        address poolTokenAddress;
        uint256 amount;
    }

    struct ExecuteBorrowParams {
        DataStore dataStore;
        address poolTokenAddress;
        uint256 amount;
    }

    // @dev executes a borrow
    // @param account the withdrawing account
    // @param params ExecuteBorrowParams
    function executeBorrow(address account, ExecuteBorrowParams calldata params) external {

        if(params.amount <= 0){revert Errors}

        Position.Props memory position = PoolStoreUtils.get(params.dataStore, account);
        if(position == null){ revert Errors }

        Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, params.poolTokenAddress);
        Pool.PoolCache memory poolCache =  PoolUtils.cache(pool);

        PoolUtils.updateIndexesAndIncrementFeeAmount(pool, poolCache);

        ExecuteBorrowUtils.validateBorrow(poolCache, position, params.amount)
        IPoolToken poolToken = IPoolToken(poolCache.poolTokenAddress);
        poolToken.addCollateral(account, params.amount);//will change borrowIndex

        position.setAsCollateral(pool.poolKeyId. true)
        position.setAsDebt(pool.poolKeyId. true)
        // PositionUtils.setCollateral(position, pool.poolKeyId)
        // PositionUtils.setDebt(position, pool.poolKeyId)
        PositionStoreUtils.set(params.dataStore, account, position);

        poolCache.nextScaledDebt = IDebtToken(poolCache.debtTokenAddress)
        .mint(account, params.amount, poolCache.nextBorrowIndex);
        
        PoolUtils.updateInterestRates(pool, poolCache, params.asset, 0, amount);
        PoolStoreUtils.set(params.dataStore, params.poolTokenAddress, PoolUtils.getPoolSalt(params.asset), pool);

    }


      // /**
      //  * @notice Validates a withdraw action.
      //  * @param poolCache The cached data of the pool
      //  * @param amount The amount to be withdrawn
      //  * @param userBalance The balance of the user
      //  */
      // function validateBorrow(
      //     Position.Props memory position,
      //     PoolCache.Props memory poolCache,
      //     uint256 amount
      // ) internal pure {
       
      //  (
      //   vars.userCollateralInBaseCurrency,
      //   vars.userDebtInBaseCurrency,
      //   var.healthFactor,
      //  ) = calculateUser()

   
      // }
    
}
