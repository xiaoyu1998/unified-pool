// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../data/DataStore.sol";
import "../error/Errors.sol";
import "../pool/Pool.sol";
// import "../pool/PoolCache.sol";
import "../pool/PoolUtils.sol";
import "../pool/PoolStoreUtils.sol";
import "../token/IPoolToken.sol";
import "../token/IDebtToken.sol";
import "../repay/RepayUtils.sol";
import "../swap/SwapUtils.sol";
//import "../oracle/OracleUtils.sol";
//import "./RepaySubstituteEventUtils.sol";

// @title RepaySubstituteUtils
// @dev Library for repay functions, to help with the repaying the debt 
// from a pool and burn the debt tokens
library RepaySubstituteUtils {
    using Pool for Pool.Props;
    using PoolCache for PoolCache.Props;
    using Position for Position.Props;

    struct RepaySubstituteParams {
        address underlyingAsset;
        uint256 amount;
        address substitute;
    }

    struct ExecuteRepaySubstituteParams {
        address dataStore;
        address eventEmitter;
        address underlyingAsset;
        uint256 amount;
        address substitute;
    }

    struct RepaySubstituteLocalVars {
        address poolKey;
        Pool.Props pool;
        IPoolToken poolToken;
        IDebtToken debtToken;
        uint256 repayAmount;
        uint256 collateralAmount;
        uint256 debtAmount;
        bool useCollateralToRepay;
        RepayUtils.ExecuteRepayParams repayParams;
        SwapUtils.ExecuteSwapParams swapParams;      
        uint256 underCollateralAmount;
    }

    // @dev executes a repay with substitute
    // @param account the repaying account
    // @param params ExecuteRepaySubstituteParams
    function executeRepaySubstitute(address account, ExecuteRepaySubstituteParams calldata params) external {
        RepaySubstituteLocalVars memory vars;
        vars.poolKey = Keys.poolKey(params.underlyingAsset);
        vars.pool = PoolStoreUtils.get(params.dataStore, vars.poolKey);
        PoolUtils.validateEnabledPool(vars.pool, vars.poolKey);

        vars.poolToken = IPoolToken(vars.pool.poolToken);
        vars.debtToken = IDebtToken(vars.pool.debtToken);

        vars.collateralAmount = vars.poolToken.balanceOfCollateral(account);
        vars.useCollateralToRepay = (params.amount > 0) ? true:false;
        if (!vars.useCollateralToRepay) {//
            vars.repayParams = RepayUtils.ExecuteRepayParams(
                params.dataStore,
                params.eventEmitter,
                params.underlyingAsset,
                0
            );
            RepayUtils.executeRepay(account, vars.repayParams);
            return;
        }

        //handle collateralToRepay
        vars.repayAmount = params.amount;
        vars.debtAmount = vars.debtToken.balanceOf(account);  
        if (vars.repayAmount > vars.debtAmount) {
            vars.repayAmount = vars.debtAmount;
        }
        //collateral enough to repay
        if (vars.repayAmount <= vars.collateralAmount) {
            vars.repayParams = RepayUtils.ExecuteRepayParams(
                params.dataStore,
                params.eventEmitter,
                params.underlyingAsset,
                vars.repayAmount
            );
            RepayUtils.executeRepay(account, vars.repayParams);
            return;
        }


        // RepayUtils.validateRepaySubstitute(
        //     account, 
        //     vars.pool,
        //     vars.repayAmount, 
        //     vars.debtAmount, 
        // );

        //sell substitute and buy underlyingAsset to repay
        vars.underCollateralAmount = vars.repayAmount - vars.collateralAmount;
        vars.swapParams = SwapUtils.ExecuteSwapParams(
            params.dataStore,
            params.eventEmitter,
            params.substitute,
            params.underlyingAsset,
            vars.underCollateralAmount,
            0
        ); 
        SwapUtils.executeSwapExactOut(account, vars.swapParams);    

        vars.repayParams = RepayUtils.ExecuteRepayParams(
            params.dataStore,
            params.eventEmitter,
            params.underlyingAsset,
            vars.repayAmount
        );
        RepayUtils.executeRepay(account, vars.repayParams);

    }
    
    // @notice Validates a repay action.
    // @param account The repaying account
    // @param pool The state of the pool
    // @param repayAmount The amount to be repay
    // @param debtAmount The amount of total debt
    // @param useCollateralToRepaySubstitute use the collateral to this repay action
    // function validateRepaySubstitute(
    //     address account,
    //     Pool.Props memory pool,
    //     uint256 repayAmount,
    //     uint256 debtAmount
    // ) internal pure {
    //     PoolUtils.validateConfigurationPool(pool, false);  

    //     if(debtAmount == 0) {
    //         revert Errors.UserDoNotHaveDebtInPool(account, pool.underlyingAsset);
    //     }
        
    //     if(repayAmount == 0) {
    //         revert Errors.EmptyRepayAmount();
    //     }

    // }
    
}
