// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../data/DataStore.sol";
import "../data/Keys.sol";
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
import "../event/EventEmitter.sol";
import "./RepayEventUtils.sol";

// @title RepayUtils
// @dev Library for deposit functions, to help with the depositing of liquidity
// into a market in return for market tokens
library RepayUtils {
    using Pool for Pool.Props;
    using PoolCache for PoolCache.Props;
    using Position for Position.Props;
    using WadRayMath for uint256;
    using PoolConfigurationUtils for uint256;

    struct RepayParams {
        address underlyingAsset;
        uint256 amount;
    }

    struct ExecuteRepayParams {
        address dataStore;
        address eventEmitter;
        address underlyingAsset;
        uint256 amount;
    }

    // @dev executes a repay
    // @param account the repaying account
    // @param params ExecuteRepayParams
    function executeRepay(address account, ExecuteRepayParams calldata params) external {
        Printer.log("-------------------------executeRepay--------------------------");
        address poolKey = Keys.poolKey(params.underlyingAsset);
        Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, poolKey);
        PoolUtils.validateEnabledPool(pool, poolKey);
        PoolCache.Props memory poolCache = PoolUtils.cache(pool);
        PoolUtils.updateStateBetweenTransactions(pool, poolCache);

        uint256 repayAmount;
        uint256 collateralAmount;
        IPoolToken poolToken = IPoolToken(poolCache.poolToken);
        bool useCollateral = (params.amount > 0) ? true:false;
        if (useCollateral) { // reduce collateral to repay
            repayAmount = params.amount;
            collateralAmount = poolToken.balanceOfCollateral(account);
        } else {//transferin to repay
            repayAmount = poolToken.recordTransferIn(params.underlyingAsset);
        }

        Printer.log("repayAmount", repayAmount);   

        uint256 extraAmountToRefund;
        IDebtToken debtToken = IDebtToken(poolCache.debtToken);
        uint256 debtAmount = debtToken.balanceOf(account);
        if (repayAmount > debtAmount) {
            extraAmountToRefund = repayAmount - debtAmount;
            repayAmount         = debtAmount;      
        }
        Printer.log("debtAmount", debtAmount); 
        Printer.log("extraAmountToRefund", extraAmountToRefund); 

        bytes32 positionKey = Keys.accountPositionKey(params.underlyingAsset, account);
        Position.Props memory position  = PositionStoreUtils.get(params.dataStore, positionKey);
        RepayUtils.validateRepay(
            account, 
            position, 
            pool, 
            repayAmount, 
            debtAmount, 
            collateralAmount
        );

        poolCache.nextTotalScaledDebt = debtToken.burn(account, repayAmount, poolCache.nextBorrowIndex);
        if (debtToken.scaledBalanceOf(account) == 0) {
            position.hasDebt = false; 
        }
        if (useCollateral) {//reduce collateral to repay
            poolToken.removeCollateral(account, repayAmount);
            if(poolToken.balanceOfCollateral(account) == 0) {
                position.hasCollateral = false;
            }
        }
        //TODO:should change to Long?
        bool poolIsUsd = PoolConfigurationUtils.getUsd(pool.configuration);
        if (debtToken.balanceOf(account) < poolToken.balanceOfCollateral(account) && 
            position.positionType == Position.PositionTypeShort && 
            !poolIsUsd
        ) {
            position.positionType = Position.PositionTypeLong;
        }
        PositionStoreUtils.set(
            params.dataStore, 
            positionKey, 
            position
        );

        PoolUtils.updateInterestRates(
            pool,
            poolCache, 
            params.underlyingAsset, 
            0, //balanceOf underlyingAsset has been added repayAmount, or Collateral has been removed repayAmount
            0
        );

        PoolStoreUtils.set(
            params.dataStore, 
            poolKey, 
            pool
        );  

        if(extraAmountToRefund > 0 && !useCollateral) {//Refund extra
            poolToken.transferOutUnderlyingAsset(account, extraAmountToRefund);
            poolToken.syncUnderlyingAssetBalance();
        }

        RepayEventUtils.emitRepay(
            params.eventEmitter, 
            params.underlyingAsset, 
            account, 
            repayAmount,
            useCollateral
        );

    }
    
    // @notice Validates a repay action.
    // @param poolCache The cached data of the pool
    // @param repayAmount The amount to be repay
    function validateRepay(
        address account,
        Position.Props memory position,
        Pool.Props memory pool,
        uint256 repayAmount,
        uint256 debtAmount,
        uint256 collateralAmount
    ) internal pure {
        (   bool isActive,
            bool isFrozen, 
            ,
            bool isPaused
        ) = pool.configuration.getFlags();
        if (!isActive) { revert Errors.PoolIsInactive(pool.underlyingAsset); }  
        if (isPaused)  { revert Errors.PoolIsPaused(pool.underlyingAsset);   }  
        if (isFrozen)  { revert Errors.PoolIsFrozen(pool.underlyingAsset);   }  

        PositionUtils.validateEnabledPosition(position);

        if(debtAmount == 0) {
            revert Errors.UserDoNotHaveDebtInPool(account, pool.underlyingAsset);
        }
        
        if(repayAmount == 0) {
            revert Errors.EmptyRepayAmount();
        }

        if(collateralAmount > 0){
            if(collateralAmount < repayAmount){
                revert Errors.InsufficientCollateralAmountForRepay(repayAmount, collateralAmount);
            }
        }
    }
    
}
