// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/DataStore.sol";
import "../data/Keys.sol";
import "../error/Errors.sol";

import "../pool/Pool.sol";
import "../pool/PoolCache.sol";
import "../pool/PoolUtils.sol";
import "../pool/PoolStoreUtils.sol";
import "../token/IPoolToken.sol";

import "../oracle/OracleUtils.sol";
import "../position/Position.sol";
import "../position/PositionUtils.sol";
import "../position/PositionStoreUtils.sol";
import "../utils/WadRayMath.sol";
import "../event/EventEmitter.sol";
import "./DepositEventUtils.sol";

// @title DepositUtils
// @dev Library for deposit functions, to help with the depositing of liquidity
// into a pool in return for pool tokens
library DepositUtils {
    using Pool for Pool.Props;
    using PoolCache for PoolCache.Props;
    using Position for Position.Props;
    using WadRayMath for uint256;
    using PoolConfigurationUtils for uint256;

    struct DepositParams {
        address underlyingAsset;
    }

    struct ExecuteDepositParams {
        address dataStore;
        address eventEmitter;
        address underlyingAsset;
    }

    struct DepositLocalVars {
        Pool.Props pool;
        PoolCache.Props poolCache;
        address poolKey;
        bool poolIsUsd;
        IPoolToken poolToken;
        IDebtToken debtToken;
        bytes32 positionKey;
        Position.Props position;
        uint256 depositAmount;
        uint256 price;
    }

    // @dev executes a deposit
    // @param account the depositing account
    // @param params ExecuteDepositParams
    function executeDeposit(address account, ExecuteDepositParams calldata params) external {
        Printer.log("-------------------------executeDeposit--------------------------");
        DepositLocalVars memory vars;
        (   vars.pool,
            vars.poolCache,
            vars.poolKey,
            vars.poolIsUsd
        ) = PoolUtils.updatePoolAndCache(params.dataStore, params.underlyingAsset);

        (   vars.position,
            vars.positionKey
        ) = PositionUtils.getOrInit(
            account,
            params.dataStore, 
            params.underlyingAsset, 
            Position.PositionTypeLong,
            vars.poolIsUsd
        );

        vars.debtToken   = IDebtToken(vars.pool.debtToken);
        vars.poolToken   = IPoolToken(vars.pool.poolToken);
        vars.depositAmount = vars.poolToken.recordTransferIn(params.underlyingAsset);

        DepositUtils.validateDeposit(
            vars.pool, 
            vars.depositAmount
        );

        vars.poolToken.addCollateral(account, vars.depositAmount);
        vars.position.hasCollateral = true;
        if (!vars.poolIsUsd){
            vars.price = OracleUtils.getPrice(params.dataStore, params.underlyingAsset);
            PositionUtils.longPosition(vars.position, vars.price, vars.depositAmount, true);
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

        DepositEventUtils.emitDeposit(
            params.eventEmitter, 
            params.underlyingAsset, 
            account, 
            vars.depositAmount,
            vars.poolToken.balanceOfCollateral(account),
            vars.debtToken.scaledBalanceOf(account)
        );
    }


    //
    // @notice Validates a deposit action.
    // @param pool The state of the pool
    // @param amount The amount to be deposit
    //
    function validateDeposit(
        Pool.Props memory pool,
        uint256 amount
    ) internal pure {
        PoolUtils.validateConfigurationPool(pool, false);   

        if (amount == 0) { 
            revert Errors.EmptyDepositAmounts(); 
        }
    }
    
}
