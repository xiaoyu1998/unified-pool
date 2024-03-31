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

import "../oracle/IPriceOracleGetter.sol";
import "../oracle/OracleStoreUtils.sol";

import "../config/ConfigStoreUtils.sol";

import "../utils/WadRayMath.sol";

// @title RedeemUtils
// @dev Library for redeem functions, to help with the redeeming of liquidity
// into a market in return for market tokens
library RedeemUtils {
    using Pool for Pool.Props;
    using PoolCache for PoolCache.Props;
    using Position for Position.Props;
    using WadRayMath for uint256;

    struct RedeemParams {
        address underlyingAsset;
        uint256 amount;
        address to;
    }

    struct ExecuteRedeemParams {
        DataStore dataStore;
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
        address poolKey = Keys.poolKey(params.underlyingAsset);
        Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, poolKey);
        PoolUtils.validateEnabledPool(pool, poolKey);

        Position.Props memory position = PositionStoreUtils.get(params.dataStore, account);
        RedeemUtils.validateRedeem( 
            account, 
            params.dataStore, 
            position, 
            pool, 
            params.amount
        );

        IPoolToken poolToken = IPoolToken(pool.poolToken);
        poolToken.removeCollateral(account, params.amount);
        if(poolToken.balanceOfCollateral(account) == 0) {
            position.setPoolAsCollateral(pool.keyId, false);
            PositionStoreUtils.set(params.dataStore, account, position);
        }

        poolToken.transferOutUnderlyingAsset(params.to, params.amount);
        poolToken.syncUnderlyingAssetBalance();
    }

    struct ValidateBorrowLocalVars {
        uint256 userTotalCollateralUsd;
        uint256 userTotalDebtUsd;
        uint256 amountToRedeemUsd;
        uint256 healthFactor;
        uint256 healthFactorCollateralRateThreshold;

        bool isActive;
        bool isFrozen;
        bool isPaused;
        bool borrowingEnabled;
    }

    // @notice Validates a redeem action.
    // @param poolCache The cached data of the pool
    // @param amount The amount to be redeemn
    // @param userBalance The balance of the user
    function validateRedeem(
        address account,
        DataStore dataStore,
        Position.Props memory position,
        Pool.Props memory pool,
        uint256 amountToRedeem
    ) internal view {
        PositionUtils.validateEnabledPosition(position);

        if(amountToRedeem == 0) {
            revert Errors.EmptyRedeemAmount();
        }

        ValidateBorrowLocalVars memory vars;

        //validate account health
        (
            vars.userTotalCollateralUsd,
            vars.userTotalDebtUsd
        ) = PositionUtils.calculateUserTotalCollateralAndDebt(account, dataStore, position);

        if (vars.userTotalCollateralUsd == 0) { 
            revert Errors.CollateralBalanceIsZero();
        }

        vars.amountToRedeemUsd = IPriceOracleGetter(OracleStoreUtils.get(dataStore))
                                   .getPrice(pool.underlyingAsset)
                                   .rayMul(amountToRedeem);
        // vars.healthFactor = userTotalCollateralUsd.wadDiv(userTotalDebtUsd + amountToRedeemUsd);
        vars.healthFactor = 
            (vars.userTotalDebtUsd + vars.amountToRedeemUsd).wadDiv(vars.userTotalCollateralUsd);
        vars.healthFactorCollateralRateThreshold =
            ConfigStoreUtils.getHealthFactorCollateralRateThreshold(dataStore);
        if (vars.healthFactor < vars.healthFactorCollateralRateThreshold) {
            revert Errors.CollateralCanNotCoverRedeem(
                vars.userTotalCollateralUsd, 
                vars.userTotalDebtUsd, 
                vars.amountToRedeemUsd,
                vars.healthFactorCollateralRateThreshold
            );
        }

    }
}
