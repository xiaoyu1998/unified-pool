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
        uint256 amount;
    }

    struct ExecuteRepayParams {
        DataStore dataStore;
        address underlyingAsset;
        uint256 amount;
    }

    // @dev executes a repay
    // @param account the repaying account
    // @param params ExecuteRepayParams
    function executeRepay(address account, ExecuteRepayParams calldata params) external {
        Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, PoolUtils.getKey(params.underlyingAsset));
        PoolUtils.validateEnabledPool(pool);
        Pool.PoolCache memory poolCache = PoolUtils.cache(pool);
        pool.updateStateByIntervalBetweenTransactions(poolCache);

        uint256 repayAmount;
        uint256 collateralAmount;
        IPoolToken poolToken = IPoolToken(poolCache.poolToken);
        if(params.amount > 0) {
            repayAmount = amount;
            collateralAmount = poolToken.balanceOfCollateral(account);
        } else {
            repayAmount = poolToken.recordTransferIn(params.underlyingAsset));
        }

        uint256 extraAmount;
        IDebtToken debtToken = IDebtToken(poolCache.debtToken);
        uint256 debtAmount = debtToken.balanceOf(account);
        if(repayAmount > debtAmount) {
            extraAmountToRefund = repayAmount - debtAmount;
            repayAmount         = debtAmount;      
        }
        RepayUtils.validateRepay(pool, poolCache, repayAmount, debtAmount, collateralAmount)

        Position.Props memory position = PoolStoreUtils.get(params.dataStore, account);
        poolCache.nextScaledDebt = debtToken.burn(account, repayAmount, poolCache.nextBorrowIndex);
        if(debtToken.scaledBalanceOf(account) == 0) {
            position.setPoolAsBorrowing(pool.poolKeyId(), false)
            PositionStoreUtils.set(params.dataStore, account, position);
        }

        if(collateralAmount > 0) {
            poolToken.removeCollateral(account, repayAmount);
            if(poolToken.balanceOfCollateral(account) == 0)) {
                position.setPoolAsCollateral(pool.poolKeyId(), false);
                PositionStoreUtils.set(params.dataStore, account, position);
            }
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

        if(extraAmountToRefund > 0) {
            IERC20(params.underlyingAsset).safeTransfer(account, extraAmountToRefund);
        }

    }


    /**
    * @notice Validates a repay action.
    * @param poolCache The cached data of the pool
    * @param amount The amount to be repay
    * @param userBalance The balance of the user
    */
    function validateRepay(
        Pool.Props memory pool,
        PoolCache.Props memory poolCache,
        uint256 repayAmount,
        uint256 debtAmount,
        IPoolToken poolToken,
        uint256 collateralAmount
    ) internal pure {
        PositionUtils.validateEnabledPosition(position);

        if(debtAmount == 0) {
            revert Errors.UserDoNotHaveDebtInPool(pool.underlyingAsset())
        }

        if(repayAmount == 0) {
            revert Errors.EmptyRepayAmount()
        }

        if(collateralAmount > 0){
            if(collateralAmount < repayAmount){
                revert Errors.InsufficientCollateralAmountForRepay(repayAmount, collateralAmount);
            }
        }
    }
    
}
