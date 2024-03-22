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

import "../oracle/IPriceOracleGetter.sol";
import "../oracle/OracleStoreUtils.sol";

import "../config/ConfigStoreUtils.sol";

// @title RedeemUtils
// @dev Library for redeem functions, to help with the redeeming of liquidity
// into a market in return for market tokens
library RedeemUtils {

    //uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 0.9e18;//ToDo as governance

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
        Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, PoolUtils.getKey(params.underlyingAsset));
        PoolUtils.validateEnabledPool(pool, PoolUtils.getKey(params.underlyingAsset));

        Position.Props memory position = PoolStoreUtils.get(params.dataStore, account);
        BorrowUtils.validateBorrow( account, params.dataStore, position, pool, params.amount);

        IPoolToken poolToken = IPoolToken(pool.poolToken);
        poolToken.removeCollateral(account, params.amount);
        if(poolToken.balanceOfCollateral(account) == 0) {
            position.setPoolAsCollateral(pool.poolKeyId(), false);
            PositionStoreUtils.set(params.dataStore, account, position);
        }

        IERC20(params.underlyingAsset).safeTransfer(params.to, params.amount);
    }

    struct ValidateBorrowLocalVars {
        uint256 userTotalCollateralInUsd;
        uint256 userTotalDebtInUsd;
        uint256 amountToBorrowInUsd;
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
    ) internal pure {
        PositionUtils.validateEnabledPosition(position);

        if(amountToRedeem == 0) {
            revert Errors.EmptyRedeemAmount();
        }

        ValidateBorrowLocalVars memory vars;

        //validate account health
        (
            vars.userTotalCollateralInUsd,
            vars.userTotalDebtInUsd
        ) = PositionUtils.calculateUserTotalCollateralAndDebt(account, dataStore, position);

        if (vars.userCollateralInUsd == 0) { 
            revert Errors.CollateralBalanceIsZero();
        }

        vars.amountToRedeemInUsd = IPriceOracleGetter(OracleStoreUtils.get(dataStore))
                                   .getPrice(pool.underlyingAsset())
                                   .rayMul(amountToRedeem);
        // vars.healthFactor = userTotalCollateralInUsd.wadDiv(userTotalDebtInUsd + amountToRedeemInUsd);
        vars.healthFactor = (vars.userTotalDebtInUsd + vars.amountToRedeemInUsd).wadDiv(vars.userTotalCollateralInUsd);
        vars.healthFactorCollateralRateThreshold = ConfigStoreUtils.getHealthFactorCollateralRateThreshold();
        if (vars.healthFactor < vars.healthFactorCollateralRateThreshold) {
            revert Errors.CollateralCanNotCoverRedeem(
                vars.userTotalCollateralInUsd, 
                vars.userTotalDebtInUsd, 
                vars.amountToRedeemInUsd,
                vars.healthFactorCollateralRateThreshold
            );
        }

    }
}
