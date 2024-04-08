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

import "../position/Position.sol";
import "../position/PositionUtils.sol";
import "../position/PositionStoreUtils.sol";

import "../utils/WadRayMath.sol";

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
        address underlyingAsset;
    }

    // @dev executes a deposit
    // @param account the depositng account
    // @param params ExecuteDepositParams
    function executeDeposit(address account, ExecuteDepositParams calldata params) external {
        address poolKey = Keys.poolKey(params.underlyingAsset);
        Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, poolKey);
        PoolUtils.validateEnabledPool(pool, poolKey);
        PoolCache.Props memory poolCache = PoolUtils.cache(pool);
        PoolUtils.updateStateBetweenTransactions(pool, poolCache);
       
        bytes32 positionKey = Keys.accountPositionKey(params.underlyingAsset, account);
        Position.Props memory position = PositionStoreUtils.get(params.dataStore, positionKey);
        if(position.account == address(0)){
            position.account = account;
            position.underlyingAsset = params.underlyingAsset;
            position.isLong = true;
            position.hasCollateral = true;
            position.hasDebt = false;
        }

        IPoolToken poolToken   = IPoolToken(pool.poolToken);
        IDebtToken debtToken   = IDebtToken(pool.poolToken);
        uint256 depositAmount = poolToken.recordTransferIn(params.underlyingAsset);

        DepositUtils.validateDeposit(
 //           position,
            pool, 
            depositAmount
        );

        PoolStoreUtils.set(
            params.dataStore, 
            params.underlyingAsset, 
            pool
        );

        poolToken.addCollateral(account, depositAmount);
        position.hasCollateral = true;

        if(debtToken.balanceOf(account) < poolToken.balanceOfCollateral(account)) {
           position.isLong = true;
        }

        PositionStoreUtils.set(
            params.dataStore, 
            positionKey, 
            position
        );
    }


    //
    // @notice Validates a withdraw action.
    // @param pool The cached data of the pool
    // @param amount The amount to be withdrawn
    // @param userBalance The balance of the user
    //
    function validateDeposit(
//        Position.Props memory position,
        Pool.Props memory pool,
        uint256 amount
    ) internal view {
        (   bool isActive,
            bool isFrozen, 
            ,
            bool isPaused
         ) = pool.configuration.getFlags();
        if (!isActive) { revert Errors.PoolIsInactive(); }  
        if (isPaused)  { revert Errors.PoolIsPaused();   }  
        if (isFrozen)  { revert Errors.PoolIsFrozen();   }   

        if (amount == 0) { 
            revert Errors.EmptyDepositAmounts(); 
        }
    }
    
}
