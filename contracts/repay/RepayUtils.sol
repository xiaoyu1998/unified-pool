// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../data/DataStore.sol";
import "../error/Errors.sol";

import "../pool/Pool.sol";
import "../pool/PoolCache.sol";
import "../pool/PoolUtils.sol";
import "../pool/PoolStoreUtils.sol";
import "../token/IPoolToken.sol";
import "../token/IDebtToken.sol";

import "../position/Position.sol";
import "../position/PositionUtils.sol";
import "../position/PositionStoreUtils.sol";

import "../utils/WadRayMath.sol";

// @title RepayUtils
// @dev Library for deposit functions, to help with the depositing of liquidity
// into a market in return for market tokens
library RepayUtils {
    using Pool for Pool.Props;
    using PoolCache for PoolCache.Props;
    using Position for Position.Props;
    using WadRayMath for uint256;

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
        Position.Props memory position  = PositionStoreUtils.get(params.dataStore, account);

        Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, PoolUtils.getKey(params.underlyingAsset));
        PoolUtils.validateEnabledPool(pool, PoolUtils.getKey(params.underlyingAsset));
        PoolCache.Props memory poolCache = PoolUtils.cache(pool);
        PoolUtils.updateStateBetweenTransactions(pool, poolCache);

        uint256 repayAmount;
        uint256 collateralAmount;
        IPoolToken poolToken = IPoolToken(poolCache.poolToken);
        if(params.amount > 0) {
            repayAmount = params.amount;
            collateralAmount = poolToken.balanceOfCollateral(account);
        } else {
            repayAmount = poolToken.recordTransferIn(params.underlyingAsset);
        }

        uint256 extraAmountToRefund;
        IDebtToken debtToken = IDebtToken(poolCache.debtToken);
        uint256 debtAmount = debtToken.balanceOf(account);
        if(repayAmount > debtAmount) {
            extraAmountToRefund = repayAmount - debtAmount;
            repayAmount         = debtAmount;      
        }

        
        RepayUtils.validateRepay(
            account, 
            position, 
            pool, 
            repayAmount, 
            debtAmount, 
            collateralAmount
        );

        //Position.Props memory position = PoolStoreUtils.get(params.dataStore, account);
        poolCache.nextTotalScaledDebt = debtToken.burn(account, repayAmount, poolCache.nextBorrowIndex);
        if(debtToken.scaledBalanceOf(account) == 0) {
            position.setPoolAsBorrowing(pool.keyId, false);
            PositionStoreUtils.set(params.dataStore, account, position);
        }

        if(collateralAmount > 0) {
            poolToken.removeCollateral(account, repayAmount);
            if(poolToken.balanceOfCollateral(account) == 0) {
                position.setPoolAsCollateral(pool.keyId, false);
                PositionStoreUtils.set(params.dataStore, account, position);
            }
        }

        PoolUtils.updateInterestRates(
            pool,
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
            poolToken.transferOutUnderlyingAsset(account, extraAmountToRefund);
            poolToken.syncUnderlyingAssetBalance();
        }

    }


    
    // @notice Validates a repay action.
    // @param poolCache The cached data of the pool
    // @param amount The amount to be repay
    // @param userBalance The balance of the user
    function validateRepay(
        address account,
        Position.Props memory position,
        Pool.Props memory pool,
        uint256 repayAmount,
        uint256 debtAmount,
        uint256 collateralAmount
    ) internal pure {
        PositionUtils.validateEnabledPosition(position);

        if(repayAmount == 0) {
            revert Errors.EmptyRepayAmount();
        }

        if(debtAmount == 0) {
            revert Errors.UserDoNotHaveDebtInPool(account, pool.underlyingAsset);
        }

        if(collateralAmount > 0){
            if(collateralAmount < repayAmount){
                revert Errors.InsufficientCollateralAmountForRepay(repayAmount, collateralAmount);
            }
        }
    }
    
}
