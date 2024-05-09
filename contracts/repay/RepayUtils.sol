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
        uint256 extraAmountToRefund;
    }

    // @dev executes a repay
    // @param account the repaying account
    // @param params ExecuteRepayParams
    function executeRepay(address account, ExecuteRepayParams calldata params) external {
        Printer.log("-------------------------executeRepay--------------------------");
        RepayLocalVars memory vars;
        (   vars.pool,
            vars.poolCache,
            vars.poolKey,
            vars.poolIsUsd
        ) = PoolUtils.updatePoolAndCache(params.dataStore, params.underlyingAsset);

        // uint256 repayAmount;
        // uint256 collateralAmount;
        vars.poolToken = IPoolToken(vars.poolCache.poolToken);
        vars.useCollateralToRepay = (params.amount > 0) ? true:false;
        if (vars.useCollateralToRepay) { 
            vars.repayAmount = params.amount;
            vars.collateralAmount = vars.poolToken.balanceOfCollateral(account);
        } else {//transferin to repay
            vars.repayAmount = vars.poolToken.recordTransferIn(params.underlyingAsset);
        }
        Printer.log("repayAmount", vars.repayAmount);   

        vars.extraAmountToRefund;
        vars.debtToken = IDebtToken(vars.poolCache.debtToken);
        vars.debtAmount = vars.debtToken.balanceOf(account);
        if (vars.repayAmount > vars.debtAmount) {
            vars.extraAmountToRefund = vars.repayAmount - vars.debtAmount;
            vars.repayAmount         = vars.debtAmount;      
        }
        Printer.log("debtAmount", vars.debtAmount); 
        Printer.log("extraAmountToRefund", vars.extraAmountToRefund); 

        vars.positionKey = Keys.accountPositionKey(params.underlyingAsset, account);
        vars.position  = PositionStoreUtils.get(params.dataStore, vars.positionKey);
        RepayUtils.validateRepay(
            account, 
            vars.pool,
            vars.position, 
            vars.repayAmount, 
            vars.debtAmount, 
            vars.collateralAmount
        );

        vars.poolCache.nextTotalScaledDebt = vars.debtToken.burn(account, vars.repayAmount, vars.poolCache.nextBorrowIndex);
        if (vars.debtToken.scaledBalanceOf(account) == 0) {
            vars.position.hasDebt = false; 
        }
        if (vars.useCollateralToRepay) {//reduce collateral to repay
            vars.poolToken.removeCollateral(account, vars.repayAmount);
            if(vars.poolToken.balanceOfCollateral(account) == 0) {
                vars.position.hasCollateral = false;
            }
        }
        if(vars.extraAmountToRefund > 0 && !vars.useCollateralToRepay) {//Refund extra
            vars.poolToken.transferOutUnderlyingAsset(account, vars.extraAmountToRefund);
            vars.poolToken.syncUnderlyingAssetBalance();
        } 

        if (!vars.poolIsUsd){
            PositionUtils.longPosition(vars.position, 0, vars.repayAmount);
        }
        PositionStoreUtils.set(
            params.dataStore, 
            vars.positionKey, 
            vars.position
        ); 

        PoolUtils.updateInterestRates(
            vars.pool,
            vars.poolCache, 
            params.underlyingAsset
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
            vars.useCollateralToRepay
        );

    }
    
    // @notice Validates a repay action.
    // @param pool The pool
    // @param repayAmount The amount to be repay
    function validateRepay(
        address account,
        Pool.Props memory pool,
        Position.Props memory position,
        uint256 repayAmount,
        uint256 debtAmount,
        uint256 collateralAmount
    ) internal pure {
        PoolUtils.validateConfigurationPool(pool, false);  
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
