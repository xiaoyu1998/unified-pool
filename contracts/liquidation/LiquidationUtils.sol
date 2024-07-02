// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../data/DataStore.sol";
import "../data/Keys.sol";
import "../error/Errors.sol";

import "../pool/Pool.sol";
import "../pool/PoolCache.sol";
import "../pool/PoolUtils.sol";
import "../pool/PoolStoreUtils.sol";
import "../token/IPoolToken.sol";

import "../position/Position.sol";
import "../position/PositionUtils.sol";
import "../position/PositionStoreUtils.sol";
import "../utils/WadRayMath.sol";
import "../event/EventEmitter.sol";
import "./LiquidationEventUtils.sol";

// @title LiquidationUtils
library LiquidationUtils {
    using Pool for Pool.Props;
    using PoolCache for PoolCache.Props;
    using Position for Position.Props;
    using WadRayMath for uint256;
    using PoolConfigurationUtils for uint256;
    using SafeERC20 for IERC20;

    struct LiquidationParams {
        address account;
    }

    struct ExecuteLiquidationParams {
        address dataStore;
        address eventEmitter;
        address account;
    }

    struct LiquidationLocalVars {
        uint256 healthFactor;
        uint256 healthFactorLiquidationThreshold;
        uint256 userTotalCollateralUsd;
        uint256 userTotalDebtUsd;
        uint256 positionCount;
        bytes32[] positionKeys;
        bytes32 positionKey;
        Position.Props position;
        Pool.Props pool;
        PoolCache.Props poolCache;
        address poolKey;
        IPoolToken poolToken;
        IDebtToken debtToken;
        uint256 collateralAmount;
        uint256 debtAmount;
        uint256 i;
    }

    // @dev executes a liquidation
    // @param params liquidator
    // @param params ExecuteLiquidationParams
    function executeLiquidation(address liquidator, ExecuteLiquidationParams calldata params) external {
        Printer.log("-------------------------executeLiquidation--------------------------");
        LiquidationLocalVars memory vars;
        (   vars.healthFactor,
            vars.healthFactorLiquidationThreshold,
            vars.userTotalCollateralUsd,
            vars.userTotalDebtUsd
        ) = LiquidationUtils.validateLiquidation(
            params.account, 
            params.dataStore
        );

        LiquidationEventUtils.emitLiquidation(
            params.eventEmitter, 
            liquidator,
            params.account,
            vars.healthFactor, 
            vars.healthFactorLiquidationThreshold,
            vars.userTotalCollateralUsd,
            vars.userTotalDebtUsd
        );

        vars.positionCount = PositionStoreUtils.getAccountPositionCount(
            params.dataStore, 
            params.account
        );
        vars.positionKeys = 
            PositionStoreUtils.getAccountPositionKeys(
                params.dataStore, 
                params.account, 
                0, 
                vars.positionCount
            );
        for (vars.i = 0; vars.i < vars.positionKeys.length; vars.i++) {
            vars.positionKey = vars.positionKeys[vars.i];
            vars.position = PositionStoreUtils.get(params.dataStore, vars.positionKey);

            (   vars.pool,
                vars.poolCache,
                vars.poolKey,
            ) = PoolUtils.updatePoolAndCache(params.dataStore, vars.position.underlyingAsset);
            PoolUtils.validateConfigurationPool(vars.pool, false);  

            vars.poolToken = IPoolToken(vars.pool.poolToken);
            vars.collateralAmount = 0;
            vars.debtAmount = 0;
            if (vars.position.hasCollateral){
                vars.collateralAmount = vars.poolToken.balanceOfCollateral(vars.position.account);
                vars.poolToken.removeCollateral(vars.position.account, vars.collateralAmount);
                vars.poolToken.transferOutUnderlyingAsset(liquidator, vars.collateralAmount);
            }
            Printer.log("collateralAmount", vars.collateralAmount);

            if (vars.position.hasDebt){
                vars.debtToken = IDebtToken(vars.pool.debtToken);
                vars.debtAmount = vars.debtToken.balanceOf(vars.position.account);
                vars.debtToken.burnAll(vars.position.account);

                //TODO:should be move to Router
                IERC20(vars.position.underlyingAsset).safeTransferFrom(
                    liquidator, 
                    address(vars.poolToken), 
                    vars.debtAmount
                );
                vars.poolToken.syncUnderlyingAssetBalance();             
            }
            Printer.log("debtAmount", vars.debtAmount);

            PositionUtils.reset(vars.position);
            PositionStoreUtils.set(params.dataStore, vars.positionKey, vars.position);

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

            LiquidationEventUtils.emitPositionLiquidation(
                params.eventEmitter, 
                liquidator,
                vars.position.underlyingAsset, 
                params.account, 
                vars.collateralAmount,
                vars.debtAmount,
                OracleUtils.getPrice(params.dataStore, vars.position.underlyingAsset)
            );
        }
    }

    struct ValidateLiquidationLocalVars {
        uint256 healthFactor;
        uint256 healthFactorLiquidationThreshold;
        bool isHealtherFactorHigherThanLiquidationThreshold;
        uint256 userTotalCollateralUsd;
        uint256 userTotalDebtUsd;
    }

    //
    // @notice Validates a liquidation action.
    //
    function validateLiquidation(
        address account,
        address dataStore
    ) internal view returns(uint256, uint256, uint256, uint256) {
        ValidateLiquidationLocalVars memory vars;
        (   vars.healthFactor,
            vars.healthFactorLiquidationThreshold,
            vars.isHealtherFactorHigherThanLiquidationThreshold,
            vars.userTotalCollateralUsd,
            vars.userTotalDebtUsd
        ) = PositionUtils.getLiquidationHealthFactor(account, dataStore);

        if (vars.isHealtherFactorHigherThanLiquidationThreshold) {
            revert Errors.HealthFactorHigherThanLiquidationThreshold(
                vars.healthFactor, 
                vars.healthFactorLiquidationThreshold
            );
        }
        
        return (vars.healthFactor,
                vars.healthFactorLiquidationThreshold,
                vars.userTotalCollateralUsd,
                vars.userTotalDebtUsd);
    }
    
}
