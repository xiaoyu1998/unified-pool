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
import "../token/IDebtToken.sol";

import "../position/Position.sol";
import "../position/PositionUtils.sol";
import "../position/PositionStoreUtils.sol";

import "../oracle/OracleUtils.sol";
import "../utils/WadRayMath.sol";
import "../event/EventEmitter.sol";
import "./BorrowEventUtils.sol";

// @title BorrowUtils
// @dev Library for borrow functions, to help with the borrowing of liquidity
// from a pool in return for debt tokens
library BorrowUtils {
    using Pool for Pool.Props;
    using PoolCache for PoolCache.Props;
    using Position for Position.Props;
    using WadRayMath for uint256;

    struct BorrowParams {
        address underlyingAsset;
        uint256 amount;
    }

    struct ExecuteBorrowParams {
        address dataStore;
        address eventEmitter;
        address underlyingAsset;
        uint256 amount;
    }

    // @dev executes a borrow
    // @param account the withdrawing account
    // @param params ExecuteBorrowParams
    function executeBorrow(address account, ExecuteBorrowParams calldata params) external {
        address poolKey = Keys.poolKey(params.underlyingAsset);
        Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, poolKey);
        PoolUtils.validateEnabledPool(pool, poolKey);
        PoolCache.Props memory poolCache = PoolUtils.cache(pool);
        PoolUtils.updateStateBetweenTransactions(pool, poolCache);
        Printer.log("-------------------------executeBorrow--------------------------");  
        Printer.log("totalFee", pool.totalFee);   
        Printer.log("unclaimedFee", pool.unclaimedFee);  

        bytes32 positionKey = Keys.accountPositionKey(params.underlyingAsset, account);
        Position.Props memory position  = PositionStoreUtils.get(params.dataStore, positionKey);
        if(position.account == address(0)){
            position.account = account;
            position.underlyingAsset = params.underlyingAsset;
            position.positionType = Position.PositionTypeShort;
        }
        BorrowUtils.validateBorrow( 
            account, 
            params.dataStore, 
            poolCache, 
            params.amount
        );

        //TODO:Should have borrow "to"
        IPoolToken(poolCache.poolToken).addCollateral(account, params.amount);//this will change Rate
        (, poolCache.nextTotalScaledDebt) = IDebtToken(poolCache.debtToken).mint(
            account, 
            params.amount, 
            poolCache.nextBorrowIndex
        );
        position.hasCollateral = true;
        position.hasDebt = true;       
        PositionStoreUtils.set(
            params.dataStore, 
            positionKey, 
            position
        );

        // IDebtToken debtToken   = IDebtToken(pool.poolToken);
        // if(debtToken.balanceOf(account) > poolToken.balanceOfCollateral(account)) {
        //    position.positionType = Position.PositionTypeShort;
        // }
        
        PoolUtils.updateInterestRates(
            pool,
            poolCache, 
            params.underlyingAsset, 
            0, 
            0 //liquidity already out while move to collateral
        );

        // Printer.log("liquidityRate", pool.liquidityRate);   
        // Printer.log("borrowRate", pool.borrowRate);   
        // Printer.log("totalFee", pool.totalFee);   
        // Printer.log("unclaimedFee", pool.unclaimedFee);   

        PoolStoreUtils.set(
            params.dataStore, 
            poolKey, 
            pool
        );

        BorrowEventUtils.emitBorrow(
            params.eventEmitter, 
            params.underlyingAsset, 
            account, 
            params.amount,
            pool.borrowRate
        );
    }

    // 
    // @notice Validates a withdraw action.
    // @param poolCache The cached data of the pool
    // @param amount The amount to be Borrow
    //
    function validateBorrow(
        address account,
        address dataStore,
        PoolCache.Props memory poolCache,
        uint256 amountToBorrow
    ) internal view {
        Printer.log("-------------------------validateBorrow--------------------------");
        //validate pool configuration
        (   bool isActive,
            bool isFrozen,
            bool borrowingEnabled,
            bool isPaused
        ) = PoolConfigurationUtils.getFlags(poolCache.configuration);  
        if (!isActive)         { revert Errors.PoolIsInactive(); }  
        if (isPaused)          { revert Errors.PoolIsPaused();   }  
        if (isFrozen)          { revert Errors.PoolIsFrozen();   }   
        if (!borrowingEnabled) { revert Errors.PoolIsNotEnabled();   } 

        if (amountToBorrow == 0) { 
            revert Errors.EmptyBorrowAmounts(); 
        }

        //validate pool borrow capacity
        uint256 poolDecimals   = PoolConfigurationUtils.getDecimals(poolCache.configuration);
        uint256 borrowCapacity = PoolConfigurationUtils.getBorrowCapacity(poolCache.configuration) 
                              * (10 ** poolDecimals);

        Printer.log("poolDecimals", poolDecimals );
        Printer.log("borrowCapacity", borrowCapacity);

        if (borrowCapacity != 0) {
            uint256 totalDebt =
                poolCache.nextTotalScaledDebt.rayMul(poolCache.nextBorrowIndex) +
                amountToBorrow;
            unchecked {
                if (totalDebt > borrowCapacity) {
                    revert Errors.BorrowCapacityExceeded(totalDebt, borrowCapacity);
                }
            }
            Printer.log("totalDebt",  totalDebt);
        }

        PositionUtils.validateHealthFactor(account, dataStore, poolCache.underlyingAsset, amountToBorrow);
    }
    
}
