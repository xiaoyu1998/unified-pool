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

    // @dev executes a deposit
    // @param account the depositng account
    // @param params ExecuteDepositParams
    function executeDeposit(address account, ExecuteDepositParams calldata params) external {
        Printer.log("-------------------------executeDeposit--------------------------");
        (   Pool.Props memory pool,
            PoolCache.Props memory poolCache,
            address poolKey,
            bool poolIsUsd
        ) = PoolUtils.updatePoolAndCache(params.dataStore, params.underlyingAsset);

        (   Position.Props memory position,
            bytes32 positionKey
        ) = PositionUtils.getOrInit(
            account,
            params.dataStore, 
            params.underlyingAsset, 
            Position.PositionTypeLong,
            poolIsUsd
        );

        IPoolToken poolToken   = IPoolToken(pool.poolToken);
        uint256 depositAmount = poolToken.recordTransferIn(params.underlyingAsset);

        DepositUtils.validateDeposit(
            poolCache, 
            depositAmount
        );

        poolToken.addCollateral(account, depositAmount);
        position.hasCollateral = true;
        if (!poolIsUsd){
            uint256 price = OracleUtils.getPrice(params.dataStore, params.underlyingAsset);
            PositionUtils.longPosition(position, price, depositAmount);
        }
        PositionStoreUtils.set(
            params.dataStore, 
            positionKey, 
            position
        );

        PoolStoreUtils.set(
            params.dataStore, 
            poolKey, 
            pool
        );

        DepositEventUtils.emitDeposit(
            params.eventEmitter, 
            params.underlyingAsset, 
            account, 
            depositAmount
        );
    }


    //
    // @notice Validates a deposit action.
    // @param pool The cached data of the pool
    // @param amount The amount to be deposit
    //
    function validateDeposit(
        PoolCache.Props memory poolCache,
        uint256 amount
    ) internal pure {
        (   bool isActive,
            bool isFrozen, 
            ,
            bool isPaused
        ) = poolCache.configuration.getFlags();
        if (!isActive) { revert Errors.PoolIsInactive(poolCache.underlyingAsset); }  
        if (isPaused)  { revert Errors.PoolIsPaused(poolCache.underlyingAsset);   }  
        if (isFrozen)  { revert Errors.PoolIsFrozen(poolCache.underlyingAsset);   }   

        if (amount == 0) { 
            revert Errors.EmptyDepositAmounts(); 
        }
    }
    
}
