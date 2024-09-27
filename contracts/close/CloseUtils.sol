// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

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
import "../repay/RepayUtils.sol";
import "../swap/SwapUtils.sol";
import "../utils/WadRayMath.sol";
import "./CloseEventUtils.sol";

// @title CloseUtils
// @dev Library for close position functions, to help with repay the debts
// and sell the collaterals in dex of positions
library CloseUtils {
    using Pool for Pool.Props;
    using PoolCache for PoolCache.Props;
    using Position for Position.Props;
    using WadRayMath for uint256;

    struct ClosePositionParams {
        address underlyingAsset;
        address underlyingAssetUsd;
        uint256 percentage;
    }

    struct ExecuteClosePositionParams {
        address dataStore;
        address eventEmitter;
        address underlyingAsset;
        address underlyingAssetUsd;
        uint256 percentage;
    }

    struct ClosePositionLocalVars {
        address poolKey;
        Pool.Props pool; 
        address poolKeyUsd;
        Pool.Props poolUsd;
        bytes32 positionKey;
        Position.Props position;
        IPoolToken poolToken;
        IDebtToken debtToken;
        IPoolToken poolTokenUsd;
        IDebtToken debtTokenUsd;
        uint256 debtAmount;
        uint256 debtAmountToClose;
        uint256 collateralAmount;
        uint256 collateralAmountToSell;
        RepayUtils.ExecuteRepayParams repayParams;
        uint256 remainCollateral;
        uint256 remainCollateralUsd;
        SwapUtils.ExecuteSwapParams swapParams;

        bool isSellPercentageCollateralOnly;
        bool isRepayAllDebt;
    }

    // @dev executes a position close
    // @param account the closing account
    // @param params ExecuteClosePositionParams
    function executeClosePosition(
        address account, 
        ExecuteClosePositionParams calldata params
    ) external {
        ClosePositionLocalVars memory vars;
        vars.poolKey = Keys.poolKey(params.underlyingAsset);
        vars.pool = PoolStoreUtils.get(params.dataStore, vars.poolKey);
        PoolUtils.validateEnabledPool(vars.pool, vars.poolKey);
        vars.poolKeyUsd = Keys.poolKey(params.underlyingAssetUsd);
        vars.poolUsd = PoolStoreUtils.get(params.dataStore, vars.poolKeyUsd);
        PoolUtils.validateEnabledPool(vars.poolUsd, vars.poolKeyUsd);
        PoolUtils.validatePoolIsUsd(vars.poolUsd, vars.poolKeyUsd);

        vars.positionKey = Keys.accountPositionKey(params.underlyingAsset, account);
        vars.position = PositionStoreUtils.get(params.dataStore, vars.positionKey);

        vars.poolToken = IPoolToken(vars.pool.poolToken);
        vars.debtToken = IDebtToken(vars.pool.debtToken);
        vars.poolTokenUsd = IPoolToken(PoolStoreUtils.getPoolToken(params.dataStore, params.underlyingAssetUsd));
        vars.debtTokenUsd = IDebtToken(PoolStoreUtils.getDebtToken(params.dataStore, params.underlyingAssetUsd));  

        vars.collateralAmount = vars.poolToken.balanceOfCollateral(account);
        vars.debtAmount = vars.debtToken.balanceOf(account);

        CloseUtils.validateClosePosition( 
            vars.pool,
            vars.poolUsd,
            vars.position,
            vars.collateralAmount,
            vars.debtAmount,
            params.percentage
        );

        vars.isSellPercentageCollateralOnly = (vars.debtAmount == 0 && params.percentage != WadRayMath.RAY);

        //sell percentage collateral only
        if (vars.position.underlyingAsset != params.underlyingAssetUsd &&
            vars.isSellPercentageCollateralOnly
        ) {
            vars.collateralAmountToSell = vars.collateralAmount.rayMul(params.percentage);
            vars.remainCollateral = vars.collateralAmount - vars.collateralAmountToSell;
            vars.swapParams = SwapUtils.ExecuteSwapParams(
                params.dataStore,
                params.eventEmitter,
                params.underlyingAsset,
                params.underlyingAssetUsd,
                vars.collateralAmountToSell,
                0
            );
            SwapUtils.executeSwapExactIn(account, vars.swapParams);  

            //TODO:stack too deep
            CloseEventUtils.emitClosePosition(
                params.eventEmitter, 
                params.underlyingAsset, 
                params.underlyingAssetUsd,
                account, 
                //vars.collateralAmount, 
                vars.collateralAmountToSell,
                //0,//debtAmount
                0,//debtAmountToClose
                0,//remainUsd
                vars.remainCollateral,
                vars.poolTokenUsd.balanceOfCollateral(account),
                vars.debtTokenUsd.scaledBalanceOf(account)  
            );
            return;          
        }

        //repay debt
        vars.isRepayAllDebt = (params.percentage == WadRayMath.RAY);
        vars.debtAmountToClose = vars.isRepayAllDebt
                                    ?vars.debtAmount
                                    :vars.debtAmount.rayMul(params.percentage);
        if (vars.debtAmountToClose > 0) {
            vars.repayParams = RepayUtils.ExecuteRepayParams(
                params.dataStore,
                params.eventEmitter,
                params.underlyingAsset,
                vars.debtAmountToClose
            );
            RepayUtils.executeRepay(account, vars.repayParams);
        }

        //sell the left collateral after 100% debt close
        vars.remainCollateral = vars.collateralAmount - vars.debtAmountToClose;
        vars.remainCollateralUsd = vars.remainCollateral;
        vars.collateralAmountToSell = 0;
        if (vars.remainCollateral > 0 && 
            params.underlyingAsset != params.underlyingAssetUsd
        ) {
            //dont sell collateral if the close pecentage is < 100%
            vars.remainCollateralUsd = 0;
   
            // sell out entire remain collateral to usd if the close pecentage is 100%
            if (vars.isRepayAllDebt ) {
                vars.collateralAmountToSell = vars.remainCollateral;
                vars.swapParams = SwapUtils.ExecuteSwapParams(
                    params.dataStore,
                    params.eventEmitter,
                    params.underlyingAsset,
                    params.underlyingAssetUsd,
                    vars.collateralAmountToSell,
                    0
                );
                vars.remainCollateralUsd = SwapUtils.executeSwapExactIn(account, vars.swapParams);
                vars.remainCollateral = 0;
            } 
        }

        //reset position after repay 100% debt close and remainCollateral == 0
        if (vars.position.underlyingAsset != params.underlyingAssetUsd &&
            vars.remainCollateral == 0 &&  //collateral == 0
            vars.isRepayAllDebt //debt == 0
        ) {
            // PositionUtils.reset(vars.position);
            // PositionStoreUtils.set(params.dataStore, vars.positionKey, vars.position); 
            //TODO: should be remove position
            PositionStoreUtils.remove(params.dataStore, vars.positionKey, account);
        }  

        //TODO:stack too deep
        CloseEventUtils.emitClosePosition(
            params.eventEmitter, 
            params.underlyingAsset, 
            params.underlyingAssetUsd,
            account, 
            // vars.collateralAmount, 
            vars.collateralAmountToSell,
            // vars.debtAmount, 
            vars.debtAmountToClose,
            vars.remainCollateral,
            vars.remainCollateralUsd,
            vars.poolTokenUsd.balanceOfCollateral(account),
            vars.debtTokenUsd.scaledBalanceOf(account)  
        );
    }

    // @dev Validates a close position action.
    // @param pool The state of the pool
    // @param poolUsd The state of the poolUsd
    // @param position The state of the position
    // @param collateralAmount The amount of collateral
    // @param debtAmount The amount of debt
    function validateClosePosition(
        Pool.Props memory pool,
        Pool.Props memory poolUsd,
        Position.Props memory position,
        uint256 collateralAmount,
        uint256 debtAmount,
        uint256 percentage
    ) internal pure {
        PoolUtils.validateConfigurationPool(pool, false);
        PoolUtils.validateConfigurationPool(poolUsd, false);
        PositionUtils.validateEnabledPosition(position);

        if (collateralAmount == 0) {
            revert Errors.EmptyCollateral();
        }

        if (collateralAmount <  debtAmount) {
            revert Errors.CollateralCanNotCoverDebt(collateralAmount, debtAmount);
        }

        if (percentage > WadRayMath.RAY){
            revert Errors.ClosePercentageExceeding();
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
        address poolKeyUsd;
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
    // @param account the closing account
    // @param params ExecuteCloseParams
    function executeClose(
        address account, 
        ExecuteCloseParams calldata params
    ) external {
        CloseLocalVars memory vars;

        vars.poolKeyUsd = Keys.poolKey(params.underlyingAssetUsd);
        vars.poolUsd = PoolStoreUtils.get(params.dataStore, vars.poolKeyUsd);
        PoolUtils.validateEnabledPool(vars.poolUsd, vars.poolKeyUsd);
        PoolUtils.validatePoolIsUsd(vars.poolUsd, vars.poolKeyUsd);

        vars.poolTokenUsd = IPoolToken(vars.poolUsd.poolToken);
        vars.amountUsdStartClose = vars.poolTokenUsd.balanceOfCollateral(account);

        (   vars.positionCount,
            vars.positionKeys 
        ) = PositionStoreUtils.getPositionKeys(account, params.dataStore);

        CloseUtils.validateClose( 
            account,
            params.dataStore,
            vars.poolUsd,
            vars.positionCount
        );
        
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
            //1.repay
            if (vars.collateralAmount > 0 && vars.debtAmount > 0) {
                vars.repayParams = RepayUtils.ExecuteRepayParams(
                    params.dataStore,
                    params.eventEmitter,
                    vars.position.underlyingAsset,
                    vars.collateralAmount // will just repay debtAmount if the collateralAmount higher than debtAmount
                );
                RepayUtils.executeRepay(account, vars.repayParams);
            }

            //2.sell
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

        // buy and repay the left debt
        for (vars.i = 0; vars.i < vars.positionCount; vars.i++) {
            vars.position = PositionStoreUtils.get(params.dataStore, vars.positionKeys[vars.i]);
            vars.poolKey = Keys.poolKey(vars.position.underlyingAsset);
            vars.pool = PoolStoreUtils.get(params.dataStore, vars.poolKey);

            vars.debtToken = IDebtToken(vars.pool.debtToken);
            vars.collateralAmountUsd = vars.poolTokenUsd.balanceOfCollateral(account);
            vars.debtAmount = vars.debtToken.balanceOf(account);
            if (vars.debtAmount > 0) {
                //3.buy 
                if (vars.position.underlyingAsset != params.underlyingAssetUsd) {
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
                }
                
                //4.repay
                vars.repayParams = RepayUtils.ExecuteRepayParams(
                    params.dataStore,
                    params.eventEmitter,
                    vars.position.underlyingAsset,
                    vars.debtAmount
                );
                RepayUtils.executeRepay(account, vars.repayParams);
            }
            //reset position for other asset, and retain the usd
            if (vars.position.underlyingAsset != params.underlyingAssetUsd) {
                // PositionUtils.reset(vars.position);
                // PositionStoreUtils.set(params.dataStore, vars.positionKeys[vars.i], vars.position); 
                //TODO: should be remove position
                PositionStoreUtils.remove(params.dataStore, vars.positionKeys[vars.i], account);
            }         
        }  
        vars.amountUsdAfterBuyCollateralAndRepay = vars.poolTokenUsd.balanceOfCollateral(account); 
        CloseEventUtils.emitClose(
            params.eventEmitter, 
            params.underlyingAssetUsd,
            account, 
            vars.amountUsdStartClose, 
            vars.amountUsdAfterRepayAndSellCollateral,
            vars.amountUsdAfterBuyCollateralAndRepay
        );
    }

    // @notice Validates a close action.
    // @param account The closing account
    // @param dataStore DataStore
    // @param positionsLength The positions number
    function validateClose(
        address account, 
        address dataStore,
        Pool.Props memory poolUsd,
        uint256 positionsLength
    ) internal view {
        if (positionsLength == 0) {
            revert Errors.EmptyPositions(account);
        }
        PoolUtils.validateConfigurationPool(poolUsd, false);

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