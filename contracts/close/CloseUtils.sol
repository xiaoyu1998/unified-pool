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
import "../oracle/OracleUtils.sol";
import "../utils/WadRayMath.sol";

import "../repay/RepayUtils.sol";
import "../swap/SwapUtils.sol";

import "../event/EventEmitter.sol";
import "./CloseEventUtils.sol";

// @title CloseUtils
// @dev Library for close position functions, to help with the close of position
// into a market in return for market tokens
library CloseUtils {
    using Pool for Pool.Props;
    using PoolCache for PoolCache.Props;
    using Position for Position.Props;
    using WadRayMath for uint256;
    using PoolConfigurationUtils for uint256;

    struct ClosePositionParams {
        address underlyingAsset;
        address underlyingAssetUsd;
    }

    struct ExecuteClosePositionParams {
        address dataStore;
        address eventEmitter;
        address underlyingAsset;
        address underlyingAssetUsd;
    }

    struct ClosePositionLocalVars {
        address poolKey;
        Pool.Props pool; 
        bytes32 positionKey;
        Position.Props position;
        IPoolToken poolToken;
        IDebtToken debtToken;
        uint256 collateralAmount;
        uint256 debtAmount;
        RepayUtils.ExecuteRepayParams repayParams;
        uint256 remainAmount;
        uint256 remainAmountUsd;
        SwapUtils.ExecuteSwapParams swapParams;

    }

    // @dev executes a position close
    // @param account the closing account
    // @param params ExecuteClosePositionParams
    function executeClosePosition(
        address account, 
        ExecuteClosePositionParams calldata params
    ) external {
        Printer.log("-------------------------executeClosePosition--------------------------");
        ClosePositionLocalVars memory vars;
        vars.poolKey = Keys.poolKey(params.underlyingAsset);
        vars.pool = PoolStoreUtils.get(params.dataStore, vars.poolKey);
        PoolUtils.validateEnabledPool(vars.pool, vars.poolKey);

        vars.positionKey = Keys.accountPositionKey(params.underlyingAsset, account);
        vars.position = PositionStoreUtils.get(params.dataStore, vars.positionKey);
        PositionUtils.validateEnabledPosition(vars.position);

        vars.poolToken = IPoolToken(vars.pool.poolToken);
        vars.debtToken = IDebtToken(vars.pool.debtToken);

        vars.collateralAmount = vars.poolToken.balanceOfCollateral(account);
        vars.debtAmount = vars.debtToken.balanceOf(account);

        CloseUtils.validateClosePosition( 
            vars.pool,
            vars.position,
            vars.collateralAmount,
            vars.debtAmount
        );
        if (vars.debtAmount > 0) {
            vars.repayParams = RepayUtils.ExecuteRepayParams(
                params.dataStore,
                params.eventEmitter,
                params.underlyingAsset,
                vars.debtAmount
            );
            RepayUtils.executeRepay(account, vars.repayParams);
        }

        vars.remainAmount = vars.collateralAmount - vars.debtAmount;
        vars.remainAmountUsd = vars.remainAmount;
        if(vars.remainAmount > 0 && params.underlyingAsset != params.underlyingAssetUsd) {
            vars.swapParams = SwapUtils.ExecuteSwapParams(
                params.dataStore,
                params.eventEmitter,
                params.underlyingAsset,
                params.underlyingAssetUsd,
                vars.remainAmount,
                0
            );

            vars.remainAmountUsd = SwapUtils.executeSwapExactIn(account, vars.swapParams);
        }

        if(vars.position.underlyingAsset != params.underlyingAssetUsd){
            PositionUtils.reset(vars.position);
            PositionStoreUtils.set(params.dataStore, vars.positionKey, vars.position); 
        }    

        CloseEventUtils.emitClosePosition(
            params.eventEmitter, 
            params.underlyingAsset, 
            params.underlyingAssetUsd,
            account, 
            vars.collateralAmount, 
            vars.debtAmount,
            vars.remainAmountUsd
        );
    }

    // @notice Validates a close position action.
    // @param poolCache The cached data of the pool
    // @param collateralAmount The amount of collateral
    // @param debtAmount The amount of debt
    function validateClosePosition(
        Pool.Props memory pool,
        Position.Props memory position,
        uint256 collateralAmount,
        uint256 debtAmount
    ) internal pure {
        Printer.log("-------------------------validateClosePosition--------------------------");
        PoolUtils.validateConfigurationPool(pool, false);
        PositionUtils.validateEnabledPosition(position);

        if (collateralAmount <  debtAmount) {
            revert Errors.CollateralCanNotCoverDebt(collateralAmount, debtAmount);
        }

    }

    struct CloseParams {
        address underlyingAssetUsd;
    }

    struct ExecuteCloseParams {
        address dataStore;
        address eventEmitter;
        address underlyingAssetUsd;
    }

    struct CloseLocalVars {
        address poolUsdKey;
        Pool.Props poolUsd;       
        IPoolToken poolTokenUsd;
        uint256 positionCount;
        bytes32[] positionKeys;
        Position.Props position;
        address poolKey;
        Pool.Props pool;
        IPoolToken poolToken;
        IDebtToken debtToken;
        uint256 collateralAmount;
        uint256 debtAmount;
        uint256 remainAmount;
        RepayUtils.ExecuteRepayParams repayParams;
        SwapUtils.ExecuteSwapParams swapParams;
        uint256 collateralAmountUsd;
        uint256 CollateralAmountNeededUsd;
        uint256 i;

        uint256 amountUsdStartClose;
        uint256 amountUsdAfterRepayAndSellCollateral;
        uint256 amountUsdAfterBuyCollateralAndRepay;
    }
    // @dev executes close an account all positions 
    // @param account the closing account's positions
    // @param params ExecuteCloseParams
    function executeClose(
        address account, 
        ExecuteCloseParams calldata params
    ) external {
        Printer.log("-------------------------executeClose--------------------------");
        CloseLocalVars memory vars;

        vars.poolUsdKey = Keys.poolKey(params.underlyingAssetUsd);
        vars.poolUsd = PoolStoreUtils.get(params.dataStore, vars.poolUsdKey);
        PoolUtils.validateEnabledPool(vars.poolUsd, vars.poolUsdKey);
        vars.poolTokenUsd = IPoolToken(vars.poolUsd.poolToken);
        vars.amountUsdStartClose = vars.poolTokenUsd.balanceOfCollateral(account);

        (   vars.positionCount,
            vars.positionKeys 
        ) = PositionStoreUtils.getPositionKeys(account, params.dataStore);

        CloseUtils.validateClose( 
            account,
            params.dataStore,
            vars.positionCount
        );
        
        Printer.log("-------------------------executeClose1st--------------------------");
        Printer.log("positionCount", vars.positionCount);
        Printer.log("amountUsdStartClose", vars.amountUsdStartClose);
        // reapy and sell collateral
        for (vars.i = 0; vars.i < vars.positionCount; vars.i++) {
            vars.position = PositionStoreUtils.get(params.dataStore, vars.positionKeys[vars.i]);
            vars.poolKey = Keys.poolKey(vars.position.underlyingAsset);
            vars.pool = PoolStoreUtils.get(params.dataStore, vars.poolKey);
            PoolUtils.validateEnabledPool(vars.pool, vars.poolKey);
            PoolUtils.validateConfigurationPool(vars.pool, false);

            vars.poolToken = IPoolToken(vars.pool.poolToken);
            vars.debtToken = IDebtToken(vars.pool.debtToken);
            vars.collateralAmount = vars.poolToken.balanceOfCollateral(account);
            vars.debtAmount = vars.debtToken.balanceOf(account);
            if (vars.debtAmount > 0) {
                vars.repayParams = RepayUtils.ExecuteRepayParams(
                    params.dataStore,
                    params.eventEmitter,
                    vars.position.underlyingAsset,
                    vars.collateralAmount // will just repay debtAmount if the collateralAmount higher than debtAmount
                );
                RepayUtils.executeRepay(account, vars.repayParams);
            }

            if (vars.collateralAmount > vars.debtAmount  && vars.position.underlyingAsset != params.underlyingAssetUsd) {
                vars.remainAmount = vars.collateralAmount - vars.debtAmount;
                vars.swapParams = SwapUtils.ExecuteSwapParams(
                    params.dataStore,
                    params.eventEmitter,
                    vars.position.underlyingAsset,
                    params.underlyingAssetUsd,
                    vars.remainAmount,
                    0//should be have a sqrtPriceLimitX96
                );
                SwapUtils.executeSwapExactIn(account, vars.swapParams);
            }
        }

        vars.amountUsdAfterRepayAndSellCollateral = vars.poolTokenUsd.balanceOfCollateral(account);
        //pre-swap will create underlyingAssetUsd position
        (   vars.positionCount,
            vars.positionKeys 
        ) = PositionStoreUtils.getPositionKeys(account, params.dataStore);
        Printer.log("-------------------------executeClose2nd--------------------------");
        Printer.log("positionCount", vars.positionCount);
        Printer.log("amountUsdAfterRepayAndSellCollateral", vars.amountUsdAfterRepayAndSellCollateral);

        // buy and repay the left debt
        for (vars.i = 0; vars.i < vars.positionCount; vars.i++) {
            vars.position = PositionStoreUtils.get(params.dataStore, vars.positionKeys[vars.i]);
            vars.poolKey = Keys.poolKey(vars.position.underlyingAsset);
            vars.pool = PoolStoreUtils.get(params.dataStore, vars.poolKey);
            // PoolUtils.validateEnabledPool(vars.pool, vars.poolKey);
            // PoolUtils.validateConfigurationPool(vars.pool, false);

            if (vars.position.underlyingAsset == params.underlyingAssetUsd) {
                continue;
            }

            vars.debtToken = IDebtToken(vars.pool.debtToken);
            vars.collateralAmountUsd = vars.poolTokenUsd.balanceOfCollateral(account);
            vars.debtAmount = vars.debtToken.balanceOf(account);
            if (vars.debtAmount > 0) {
                vars.swapParams = SwapUtils.ExecuteSwapParams(
                    params.dataStore,
                    params.eventEmitter,
                    params.underlyingAssetUsd,
                    vars.position.underlyingAsset,
                    vars.debtAmount,
                    0//should be have a sqrtPriceLimitX96
                );
                vars.CollateralAmountNeededUsd = SwapUtils.executeSwapExactOut(account, vars.swapParams);
                if (vars.CollateralAmountNeededUsd > vars.collateralAmountUsd) {
                    revert Errors.UsdCollateralCanNotCoverDebt(
                        vars.collateralAmount, 
                        vars.CollateralAmountNeededUsd, 
                        vars.debtAmount, 
                        vars.position.underlyingAsset
                    );
                }

                vars.repayParams = RepayUtils.ExecuteRepayParams(
                    params.dataStore,
                    params.eventEmitter,
                    vars.position.underlyingAsset,
                    vars.debtAmount
                );
                RepayUtils.executeRepay(account, vars.repayParams);
            }
            
            PositionUtils.reset(vars.position);
            PositionStoreUtils.set(params.dataStore, vars.positionKeys[vars.i], vars.position);          
        }  
        vars.amountUsdAfterBuyCollateralAndRepay = vars.poolTokenUsd.balanceOfCollateral(account); 
        Printer.log("amountUsdAfterBuyCollateralAndRepay", vars.amountUsdAfterBuyCollateralAndRepay);
        CloseEventUtils.emitClose(
            params.eventEmitter, 
            params.underlyingAssetUsd,
            account, 
            vars.amountUsdStartClose, 
            vars.amountUsdAfterRepayAndSellCollateral,
            vars.amountUsdAfterBuyCollateralAndRepay
        );
    }

    // @notice Validates a close position action.
    // @param poolCache The cached data of the pool
    // @param collateralAmount The amount of collateral
    // @param debtAmount The amount of debt
    function validateClose(
        address account, 
        address dataStore,
        uint256 positionsLength
    ) internal view {
        Printer.log("-------------------------validateClose--------------------------");
        if (positionsLength == 0) {
            revert Errors.EmptyPositions(account);
        }

        (   uint256 healthFactor,
            uint256 healthFactorLiquidationThreshold,
            bool isHealtherFactorHigherThanLiquidationThreshold,
            ,
        ) = PositionUtils.getLiquidationHealthFactor(account, dataStore);

        if (!isHealtherFactorHigherThanLiquidationThreshold) {
            revert Errors.HealthFactorLowerThanLiquidationThreshold(
                healthFactor, 
                healthFactorLiquidationThreshold
            );
        }


    }
}