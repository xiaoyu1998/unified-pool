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

import "../event/EventEmitter.sol";
import "./RedeemEventUtils.sol";

// @title RedeemUtils
// @dev Library for redeem functions, to help with the redeeming of liquidity
// into a market in return for market tokens
library RedeemUtils {
    using Pool for Pool.Props;
    using PoolCache for PoolCache.Props;
    using Position for Position.Props;
    using WadRayMath for uint256;
    using PoolConfigurationUtils for uint256;

    struct RedeemParams {
        address underlyingAsset;
        uint256 amount;
        address to;
    }

    struct ExecuteRedeemParams {
        address dataStore;
        address eventEmitter;
        address underlyingAsset;
        uint256 amount;
        address to;
    }

    struct ExecuteRedeemLocalVars {
        Pool.Props pool;
        address poolKey;
        bool poolIsUsd;
        Position.Props position;
        bytes32 positionKey;
        uint256 redeemAmount;
        IPoolToken poolToken;
        IDebtToken debtToken;
        uint256 collateralAmount;
        uint256 maxAmountToRedeem;
        uint256 remainCollateral;
        uint256 price;
    }

    // @dev executes a redeem
    // @param account the redeemng account
    // @param params ExecuteRedeemParams
    function executeRedeem(
        address account, 
        ExecuteRedeemParams calldata params
    ) external {
        Printer.log("-------------------------executeRedeem--------------------------");
        ExecuteRedeemLocalVars memory vars;
        //TODO:should be just get the pooltoken and pool configuration only
        (   vars.pool,
            ,
            vars.poolKey,
            vars.poolIsUsd
        ) = PoolUtils.updatePoolAndCache(params.dataStore, params.underlyingAsset);

        vars.positionKey = Keys.accountPositionKey(params.underlyingAsset, account);
        vars.position = PositionStoreUtils.get(params.dataStore, vars.positionKey);
        
        vars.redeemAmount = params.amount;
        vars.debtToken   = IDebtToken(vars.pool.debtToken);
        vars.poolToken = IPoolToken(vars.pool.poolToken);
        vars.collateralAmount = vars.poolToken.balanceOfCollateral(account); 
        vars.maxAmountToRedeem = PositionUtils.maxAmountToRedeem(account, params.dataStore, params.underlyingAsset, vars.collateralAmount);  
        if (vars.redeemAmount > vars.maxAmountToRedeem) {
            vars.redeemAmount = vars.maxAmountToRedeem;
        }
        // Printer.log("redeemAmount", vars.redeemAmount);  
        RedeemUtils.validateRedeem( 
            account, 
            params.dataStore, 
            vars.pool, 
            vars.position, 
            vars.redeemAmount
        );

        vars.poolToken.removeCollateral(account, vars.redeemAmount);
        vars.poolToken.transferOutUnderlyingAsset(params.to, vars.redeemAmount);
        vars.remainCollateral = vars.poolToken.balanceOfCollateral(account);
        if (vars.remainCollateral == 0) {
            vars.position.hasCollateral = false;
        }
        if (!vars.poolIsUsd){
            vars.price = OracleUtils.getPrice(params.dataStore, params.underlyingAsset);
            PositionUtils.shortPosition(vars.position, vars.price, vars.redeemAmount, false);
        }
        PositionStoreUtils.set(
            params.dataStore, 
            vars.positionKey, 
            vars.position
        );

        PoolStoreUtils.set(
            params.dataStore, 
            vars.poolKey, 
            vars.pool
        );

        RedeemEventUtils.emitRedeem(
            params.eventEmitter, 
            params.underlyingAsset, 
            account, 
            params.to, 
            vars.redeemAmount,
            vars.poolToken.balanceOfCollateral(account),
            vars.debtToken.scaledBalanceOf(account)
        );
    }

    // @notice Validates a redeem action.
    // @param pool The pool
    // @param amountToRedeem The amount to be redeemn
    function validateRedeem(
        address account,
        address dataStore,
        Pool.Props memory pool,
        Position.Props memory position,
        uint256 amountToRedeem
    ) internal view {
        Printer.log("-------------------------validateRedeem--------------------------");
        PoolUtils.validateConfigurationPool(pool, false);  
        PositionUtils.validateEnabledPosition(position);
        if (amountToRedeem == 0) {
            revert Errors.EmptyRedeemAmount();
        }
        uint256 configuration = PoolStoreUtils.getConfiguration(dataStore, pool.underlyingAsset);
        uint256 decimals = PoolConfigurationUtils.getDecimals(configuration);

        PositionUtils.validateLiquidationHealthFactor(
            account, 
            dataStore, 
            pool.underlyingAsset, 
            amountToRedeem,
            decimals
        );

        // IPoolToken poolCacheToken = IPoolToken(pool.poolToken);
        // IDebtToken debtToken   = IDebtToken(pool.debtToken);
        // uint256 collateralAmount = poolCacheToken.balanceOfCollateral(account);
        // uint256 debtAmount = debtToken.balanceOf(account);
        // PositionUtils.validateCollateralRateHealthFactor(dataStore, pool.underlyingAsset, collateralAmount, debtAmount, amountToRedeem);

    }
}
