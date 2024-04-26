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

    // @dev executes a redeem
    // @param account the redeemng account
    // @param params ExecuteRedeemParams
    function executeRedeem(
        address account, 
        ExecuteRedeemParams calldata params
    ) external {
        Printer.log("-------------------------executeRedeem--------------------------");
        //TODO:should be just get the pooltoken and pool configuration only
        (   Pool.Props memory pool,
            PoolCache.Props memory poolCache,
            address poolKey,
            bool poolIsUsd
        ) = PoolUtils.updatePoolAndCache(params.dataStore, params.underlyingAsset);

        bytes32 positionKey = Keys.accountPositionKey(params.underlyingAsset, account);
        Position.Props memory position = PositionStoreUtils.get(params.dataStore, positionKey);
        
        uint256 redeemAmount = params.amount;
        IPoolToken poolToken = IPoolToken(pool.poolToken);
        uint256 collateralAmount = poolToken.balanceOfCollateral(account);
        uint256 maxAmountToRedeem = PositionUtils.maxAmountToRedeem(account, params.dataStore, params.underlyingAsset, collateralAmount);
        if( redeemAmount > maxAmountToRedeem) {
            redeemAmount = maxAmountToRedeem;
        }
        //Printer.log("repayAmount", redeemAmount);  

        RedeemUtils.validateRedeem( 
            account, 
            params.dataStore, 
            position, 
            pool, 
            redeemAmount
        );

        PoolStoreUtils.set(
            params.dataStore, 
            poolKey, 
            pool
        );

        poolToken.removeCollateral(account, redeemAmount);
        uint256 remainCollateral = poolToken.balanceOfCollateral(account);
        if (remainCollateral == 0) {
            position.hasCollateral = false;
        }

        if (!poolIsUsd){
            PositionUtils.shortPosition(position, 0, redeemAmount);
        }

        PositionStoreUtils.set(
            params.dataStore, 
            positionKey, 
            position
        );

        poolToken.transferOutUnderlyingAsset(params.to, redeemAmount);
        poolToken.syncUnderlyingAssetBalance();

        RedeemEventUtils.emitRedeem(
            params.eventEmitter, 
            params.underlyingAsset, 
            account, 
            params.to, 
            redeemAmount
        );
    }

    // @notice Validates a redeem action.
    // @param poolCache The cached data of the pool
    // @param amountToRedeem The amount to be redeemn
    function validateRedeem(
        address account,
        address dataStore,
        Position.Props memory position,
        Pool.Props memory pool,
        uint256 amountToRedeem
    ) internal view {
        Printer.log("-------------------------validateRedeem--------------------------");
        (   bool isActive,
            bool isFrozen, 
            ,
            bool isPaused
        ) = pool.configuration.getFlags();
        if (!isActive) { revert Errors.PoolIsInactive(pool.underlyingAsset); }  
        if (isPaused)  { revert Errors.PoolIsPaused(pool.underlyingAsset);   }  
        if (isFrozen)  { revert Errors.PoolIsFrozen(pool.underlyingAsset);   }  


        PositionUtils.validateEnabledPosition(position);

        if(amountToRedeem == 0) {
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

        // IPoolToken poolToken = IPoolToken(pool.poolToken);
        // IDebtToken debtToken   = IDebtToken(pool.debtToken);
        // uint256 collateralAmount = poolToken.balanceOfCollateral(account);
        // uint256 debtAmount = debtToken.balanceOf(account);
        // PositionUtils.validateCollateralRateHealthFactor(dataStore, pool.underlyingAsset, collateralAmount, debtAmount, amountToRedeem);

    }
}
