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
        Printer.log("-------------------------executeBorrow--------------------------");  
        address poolKey = Keys.poolKey(params.underlyingAsset);
        Pool.Props memory pool = PoolStoreUtils.get(params.dataStore, poolKey);
        PoolUtils.validateEnabledPool(pool, poolKey);
        PoolCache.Props memory poolCache = PoolUtils.cache(pool);
        PoolUtils.updateStateBetweenTransactions(pool, poolCache);
        // Printer.log("totalFee", pool.totalFee);   
        // Printer.log("unclaimedFee", pool.unclaimedFee);  
        
        bool poolIsUsd = PoolConfigurationUtils.getUsd(pool.configuration);
        bytes32 positionKey = Keys.accountPositionKey(params.underlyingAsset, account);
        Position.Props memory position  = PositionStoreUtils.get(params.dataStore, positionKey);
        if(position.account == address(0)){
            position.account = account;
            position.underlyingAsset = params.underlyingAsset;
            position.positionType = Position.PositionTypeNone;
            if (!poolIsUsd) {
                position.positionType = Position.PositionTypeShort;
            }
        }
        BorrowUtils.validateBorrow( 
            account, 
            params.dataStore, 
            poolCache, 
            params.amount
        );

        //TODO:Should have borrow "to"
        IPoolToken poolToken = IPoolToken(poolCache.poolToken);
        poolToken.addCollateral(account, params.amount);//this line will change Rate
        (, poolCache.nextTotalScaledDebt) = IDebtToken(poolCache.debtToken).mint(
            account, 
            params.amount, 
            poolCache.nextBorrowIndex
        );
        position.hasCollateral = true;
        position.hasDebt = true; 
        //TODO:should change to short?      
        IDebtToken debtToken   = IDebtToken(pool.poolToken);

        if (!poolIsUsd){
            uint256 price = OracleUtils.getPrice(params.dataStore, params.underlyingAsset);
            PositionUtils.shortPosition(position, price, params.amount);
        }

        PositionStoreUtils.set(
            params.dataStore, 
            positionKey, 
            position
        );
        
        PoolUtils.updateInterestRates(
            pool,
            poolCache, 
            params.underlyingAsset, 
            0, 
            0 //liquidity has been added while move to collateral
        );   

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
        if (!isActive)         { revert Errors.PoolIsInactive(poolCache.underlyingAsset); }  
        if (isPaused)          { revert Errors.PoolIsPaused(poolCache.underlyingAsset);   }  
        if (isFrozen)          { revert Errors.PoolIsFrozen(poolCache.underlyingAsset);   }   
        if (!borrowingEnabled) { revert Errors.PoolIsNotBorrowing(poolCache.underlyingAsset);   } 

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

        PositionUtils.validateLiquidationHealthFactor(
            account, 
            dataStore, 
            poolCache.underlyingAsset, 
            amountToBorrow
        );

        IPoolToken poolToken = IPoolToken(poolCache.poolToken);
        IDebtToken debtToken   = IDebtToken(poolCache.poolToken);
        uint256 collateralAmount = poolToken.balanceOfCollateral(account);
        uint256 debtAmount = debtToken.balanceOf(account);
        PositionUtils.validateCollateralRateHealthFactor(
            dataStore, 
            poolCache.underlyingAsset, 
            collateralAmount, 
            debtAmount, 
            amountToBorrow
        );
    }
    
}
