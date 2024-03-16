// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../position/Position.sol";
import "../position/PositionStoreUtils.sol";
import "../position/PositionUtils.sol";

// @title RepayUtils
// @dev Library for deposit functions, to help with the depositing of liquidity
// into a market in return for market tokens
library RepayUtils {

    struct RepayParams {
        address underlyingAsset;
        //uint256 amount;
    }

    struct ExecuteRepayParams {
        DataStore dataStore;
        address underlyingAsset;
        //uint256 amount;
    }

    // @dev executes a repay
    // @param account the repaying account
    // @param params ExecuteRepayParams
    function executeRepay(address account, ExecuteRepayParams calldata params) external {
        Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, PoolUtils.getKey(params.underlyingAsset));
        PoolUtils.validateEnabledPool(pool);
        Pool.PoolCache memory poolCache = PoolUtils.cache(pool);
        pool.updateStateByIntervalBetweenTransactions(poolCache);

        IPoolToken poolToken = IPoolToken(poolCache.poolToken);
        uint256 repayAmount = poolToken.recordTransferIn(params.underlyingAsset));

        Position.Props memory position = PoolStoreUtils.get(params.dataStore, account);
        RepayUtils.validateRepay(pool, poolCache, position, repayAmount)

        IDebtToken debtToken = IDebtToken(poolCache.debtToken);
        poolCache.nextScaledDebt = debtToken.burn(account, repayAmount, poolCache.nextBorrowIndex);
        if(debtToken.scaledBalanceOf(account) == 0) {
            position.setPoolAsBorrowing(pool.poolKeyId(), false)
        }
        poolToken.removeCollateral(account, repayAmount);
        if(poolToken.balanceOfCollateral(account) == 0)) {
            position.setPoolAsCollateral(pool.poolKeyId(), false)
        }
        if(debtToken.scaledBalanceOf(account) == 0 | poolToken.balanceOfCollateral(account) == 0))  {
            PositionStoreUtils.set(params.dataStore, account, position);
        }

        pool.updateInterestRates(
            poolCache, 
            params.underlyingAsset, 
            repayAmount, 
            0
        );

        PoolStoreUtils.set(
            params.dataStore, 
            params.underlyingAsset, 
            pool
        );

    }


      // /**
      //  * @notice Validates a repay action.
      //  * @param poolCache The cached data of the pool
      //  * @param amount The amount to be repay
      //  * @param userBalance The balance of the user
      //  */
      // function validateRepay(
      //     Position.Props memory position,
      //     PoolCache.Props memory poolCache,
      //     Position.Props memory position
      //     uint256 amount
      // ) internal pure {
       
      //  (
      //  PositionUtils.validateEnabledPosition(position);
      // }
    
}
