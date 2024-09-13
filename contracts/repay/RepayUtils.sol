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
import "../oracle/OracleUtils.sol";
import "./RepayEventUtils.sol";

// @title RepayUtils
// @dev Library for repay functions, to help with the repaying the debt 
// from a pool and burn the debt tokens
library RepayUtils {
    using Pool for Pool.Props;
    using PoolCache for PoolCache.Props;
    using Position for Position.Props;

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

    struct RepayLocalVars {
        Pool.Props pool;
        PoolCache.Props poolCache;
        address poolKey;
        bool poolIsUsd;
        IPoolToken poolToken;
        IDebtToken debtToken;
        bytes32 positionKey;
        Position.Props position;
        uint256 repayAmount;
        uint256 collateralAmount;
        uint256 debtAmount;
        bool useCollateralToRepay;
        uint256 overpaymentAmount;
        bool noDebtLeft;
    }

    // @dev executes a repay
    // @param account the repaying account
    // @param params ExecuteRepayParams
    function executeRepay(address account, ExecuteRepayParams calldata params) external {
        RepayLocalVars memory vars;
        (   vars.pool,
            vars.poolCache,
            vars.poolKey,
            vars.poolIsUsd
        ) = PoolUtils.updatePoolAndCache(params.dataStore, params.underlyingAsset);

        vars.poolToken = IPoolToken(vars.poolCache.poolToken);
        vars.useCollateralToRepay = (params.amount > 0) ? true:false;
        if (vars.useCollateralToRepay) { 
            vars.repayAmount = params.amount;
            vars.collateralAmount = vars.poolToken.balanceOfCollateral(account);
        } else {//transferin to repay
            vars.repayAmount = vars.poolToken.recordTransferIn(params.underlyingAsset);
        }  

        vars.overpaymentAmount;
        vars.debtToken = IDebtToken(vars.poolCache.debtToken);
        vars.debtAmount = vars.debtToken.balanceOf(account);
        if (vars.repayAmount > vars.debtAmount) {
            vars.overpaymentAmount = vars.repayAmount - vars.debtAmount;
            vars.repayAmount       = vars.debtAmount;      
        }

        vars.positionKey = Keys.accountPositionKey(params.underlyingAsset, account);
        vars.position  = PositionStoreUtils.get(params.dataStore, vars.positionKey);
        RepayUtils.validateRepay(
            account, 
            vars.pool,
            vars.position, 
            vars.repayAmount, 
            vars.debtAmount, 
            vars.collateralAmount,
            vars.useCollateralToRepay
        );

        //burn debt
        if (vars.repayAmount == vars.debtAmount){
            vars.noDebtLeft = true;
            vars.poolCache.nextTotalScaledDebt
              = vars.debtToken.burnAll(account);
        } else {
            (   vars.noDebtLeft, 
                vars.poolCache.nextTotalScaledDebt
            ) = vars.debtToken.burn(account, vars.repayAmount, vars.poolCache.nextBorrowIndex);
        }
        //repay TODO:should test burn can clear all debt base on rayMul/rayDiv
        // (   vars.noDebtLeft, 
        //     vars.poolCache.nextTotalScaledDebt
        // ) = vars.debtToken.burn(account, vars.repayAmount, vars.poolCache.nextBorrowIndex);

        if (vars.noDebtLeft){
            vars.position.hasDebt = false; 
        }
        if (vars.useCollateralToRepay) {//reduce collateral to repay
            if(vars.poolToken.removeCollateral(account, vars.repayAmount) == 0) {
                vars.position.hasCollateral = false;
            }
        }
        if(vars.overpaymentAmount > 0 && !vars.useCollateralToRepay) {//Refund extra
            vars.poolToken.transferOutUnderlyingAsset(account, vars.overpaymentAmount);
            vars.poolToken.syncUnderlyingAssetBalance();
        } 

        if (!vars.poolIsUsd && !vars.useCollateralToRepay){
            uint256 price = OracleUtils.getPrice(params.dataStore, params.underlyingAsset);
            PositionUtils.longPosition(vars.position, price, vars.repayAmount, false);
        }
        PositionStoreUtils.set(
            params.dataStore, 
            vars.positionKey, 
            vars.position
        ); 

        PoolUtils.updateInterestRates(
            params.eventEmitter,
            vars.pool,
            vars.poolCache
        );
        PoolStoreUtils.set(
            params.dataStore, 
            vars.poolKey, 
            vars.pool
        );

        RepayEventUtils.emitRepay(
            params.eventEmitter, 
            params.underlyingAsset, 
            account, 
            vars.repayAmount,
            vars.useCollateralToRepay,
            vars.poolToken.balanceOfCollateral(account),
            vars.debtToken.scaledBalanceOf(account)            
        );

    }
    
    // @notice Validates a repay action.
    // @param account The repaying account
    // @param pool The state of the pool
    // @param position The state of the position
    // @param repayAmount The amount to be repay
    // @param debtAmount The amount of total debt
    // @param collateralAmount The amount of total collateral
    // @param useCollateralToRepay use the collateral to this repay action
    function validateRepay(
        address account,
        Pool.Props memory pool,
        Position.Props memory position,
        uint256 repayAmount,
        uint256 debtAmount,
        uint256 collateralAmount,
        bool useCollateralToRepay
    ) internal pure {
        PoolUtils.validateConfigurationPool(pool, false);  
        PositionUtils.validateEnabledPosition(position);

        if(debtAmount == 0) {
            revert Errors.UserDoNotHaveDebtInPool(account, pool.underlyingAsset);
        }
        
        if(repayAmount == 0) {
            revert Errors.EmptyRepayAmount();
        }

        if(useCollateralToRepay){
            if(collateralAmount < repayAmount){
                revert Errors.InsufficientCollateralAmountForRepay(repayAmount, collateralAmount);
            }
        }
    }
    
}
