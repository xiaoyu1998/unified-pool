// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../error/Errors.sol";


// @title PoolConfigurationUtils
// @dev Library for Pool Configuration
library PoolConfigurationUtils {
    uint256 internal constant DECIMALS_MASK =                  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant ACTIVE_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant FROZEN_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant BORROWING_MASK =                 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant USD_MASK =                       0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant PAUSED_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF; // prettier-ignore  
    uint256 internal constant POOL_FEE_FACTOR_MASK =           0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF;
    uint256 internal constant BORROW_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant SUPPLY_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

    uint256 internal constant POOL_DECIMALS_START_BIT_POSITION = 48;
    uint256 internal constant IS_ACTIVE_START_BIT_POSITION = 56;
    uint256 internal constant IS_FROZEN_START_BIT_POSITION = 57;
    uint256 internal constant BORROWING_ENABLED_START_BIT_POSITION = 58;
    uint256 internal constant IS_USD_START_BIT_POSITION = 59;
    uint256 internal constant IS_PAUSED_START_BIT_POSITION = 60;
    uint256 internal constant POOL_FACTOR_START_BIT_POSITION = 64;
    uint256 internal constant BORROW_CAP_START_BIT_POSITION = 80;
    uint256 internal constant SUPPLY_CAP_START_BIT_POSITION = 116;

    uint256 internal constant MAX_VALID_DECIMALS = 255;
    uint256 internal constant MAX_VALID_BORROW_CAP = 68719476735;
    uint256 internal constant MAX_VALID_SUPPLY_CAP = 68719476735;
    uint256 internal constant MAX_VALID_FEE_FACTOR = 65535;


    uint256 public constant DEBT_CEILING_DECIMALS = 2;
    uint16 public constant MAX_POOLS_COUNT = 128;
    // 
    //   @notice Gets the configuration flags of the pool
    //   @param self The pool configuration
    //   @return The state flag representing active
    //   @return The state flag representing frozen
    //   @return The state flag representing borrowing enabled
    //   @return The state flag representing paused
    function getFlags(
        uint256 poolConfigration
    ) internal pure returns (bool, bool, bool, bool) {
        return (
            (poolConfigration & ~ACTIVE_MASK) != 0,
            (poolConfigration & ~FROZEN_MASK) != 0,
            (poolConfigration & ~BORROWING_MASK) != 0,
            (poolConfigration & ~PAUSED_MASK) != 0
        );
    }

    // @notice Sets the active state of the pool
    // @param self The pool configuration
    // @param active The active state
    function setActive(uint256 poolConfigration, bool active) internal pure returns (uint256) {

        return (poolConfigration & ACTIVE_MASK) |
               (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
    }


    // @notice Gets the active state of the pool
    // @param self The pool configuration
    // @return The active state
    function getActive(uint256 poolConfigration) internal pure returns (bool) {
        return (poolConfigration & ~ACTIVE_MASK) != 0;
    }


    // @notice Sets the frozen state of the pool
    // @param self The pool configuration
    // @param frozen The frozen state
    function setFrozen(uint256 poolConfigration, bool frozen) internal pure returns (uint256)  {
        return (poolConfigration & FROZEN_MASK) |
               (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
    }

      
    // @notice Gets the frozen state of the pool
    // @param self The pool configuration
    // @return The frozen state
    function getFrozen(uint256 poolConfigration) internal pure returns (bool) {
        return (poolConfigration & ~FROZEN_MASK) != 0;
    }

      
    // @notice Sets the paused state of the pool
    // @param self The pool configuration
    // @param paused The paused state
    function setPaused(
        uint256 poolConfigration, 
        bool paused
    ) internal pure returns (uint256) {
        return (poolConfigration & PAUSED_MASK) |
               (uint256(paused ? 1 : 0) << IS_PAUSED_START_BIT_POSITION);
    }
      
    // @notice Gets the usd state of the pool
    // @param self The pool configuration
    // @return The usd state
    function getPaused(
        uint256 poolConfigration
    ) internal pure returns (bool) {
        return (poolConfigration & ~PAUSED_MASK) != 0;
    }

    // @notice Sets the paused state of the pool
    // @param self The pool configuration
    // @param paused The paused state
    function setUsd(
        uint256 poolConfigration, 
        bool isUsd
    ) internal pure returns (uint256) {
        return (poolConfigration & USD_MASK) |
               (uint256(isUsd ? 1 : 0) << IS_USD_START_BIT_POSITION);
    }
      
    // @notice Gets the usd state of the pool
    // @param self The pool configuration
    // @return The paused state
    function getUsd(
        uint256 poolConfigration
    ) internal pure returns (bool) {
        return (poolConfigration & ~USD_MASK) != 0;
    }

    // @notice Sets the borrowing state of the pool
    // @param self The pool configuration
    // @param paused The paused state
    function setBorrowingEnabled(
        uint256 poolConfigration, 
        bool enabled
    ) internal pure returns (uint256) {
        return (poolConfigration & BORROWING_MASK) |
               (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
    }

    // @notice Gets the borrowing state of the pool
    // @param self The pool configuration
    // @return The borrowing state
    function getBorrowingEnabled(
        uint256 poolConfigration
    ) internal pure returns (bool) {
        return (poolConfigration & ~BORROWING_MASK) != 0;
    }

    // @notice Sets the decimals of the underlying asset of the pool
    // @param self The pool configuration
    // @param decimals The decimals
    function setDecimals(
        uint256 poolConfigration,
        uint256 decimals
    ) internal pure returns (uint256) {
        if (decimals > MAX_VALID_DECIMALS) {
            revert Errors.InvalidDecimals(decimals, MAX_VALID_DECIMALS);
        }

        return (poolConfigration & DECIMALS_MASK) | (decimals << POOL_DECIMALS_START_BIT_POSITION);
    }

    // @notice Gets the decimals of the underlying asset of the pool
    // @param self The pool configuration
    // @return The decimals of the asset
    function getDecimals(
        uint256 poolConfigration
    ) internal pure returns (uint256) {
        return (poolConfigration & ~DECIMALS_MASK) >> POOL_DECIMALS_START_BIT_POSITION;
    }

    // @notice Sets the fee factor of the fee
    // @param poolConfigration The fee configuration
    // @param feeFactor The fee factor
    function setFeeFactor(
        uint256 poolConfigration,
        uint256 feeFactor
    ) internal pure returns (uint256) {
        if (feeFactor > MAX_VALID_FEE_FACTOR) {
            revert Errors.InvalidFeeFactor(feeFactor, MAX_VALID_FEE_FACTOR);
        }

        return (poolConfigration & POOL_FEE_FACTOR_MASK) |
               (feeFactor << POOL_FACTOR_START_BIT_POSITION);
    }

    // @notice Gets the fee factor of the pool
    // @param self The pool configuration
    // @return The pool factor
    function getFeeFactor(
        uint256 poolConfigration
    ) internal pure returns (uint256) {
        return (poolConfigration & ~POOL_FEE_FACTOR_MASK) >> POOL_FACTOR_START_BIT_POSITION;
    }

    
    // @notice Sets the borrow cap of the pool
    // @param self The pool configuration
    // @param borrowCapacity The borrow cap
    function setBorrowCapacity(
        uint256 poolConfigration,
        uint256 borrowCapacity
    ) internal pure returns (uint256) {
        if (borrowCapacity > MAX_VALID_BORROW_CAP) {
            revert Errors.InvalidBorrowCapacity(borrowCapacity, MAX_VALID_BORROW_CAP);
        }
        return (poolConfigration & BORROW_CAP_MASK) | (borrowCapacity << BORROW_CAP_START_BIT_POSITION);
    }

    // @notice Gets the borrow cap of the pool
    // @param self The pool configuration
    // @return The borrow cap
    function getBorrowCapacity(
        uint256 poolConfigration
    ) internal pure returns (uint256) {
        return (poolConfigration & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
    }

    // @notice Sets the supply cap of the pool
    // @param self The pool configuration
    // @param supplyCapacity The supply cap
    function setSupplyCapacity(
        uint256 poolConfigration,
        uint256 supplyCapacity
    ) internal pure returns (uint256) {
        if (supplyCapacity > MAX_VALID_SUPPLY_CAP) {
            revert Errors.InvalidSupplyCapacity(supplyCapacity, MAX_VALID_SUPPLY_CAP);
        }
        return (poolConfigration & SUPPLY_CAP_MASK) | (supplyCapacity << SUPPLY_CAP_START_BIT_POSITION);
    }

    // @notice Gets the supply cap of the pool
    // @param self The pool configuration
    // @return The supply cap
    function getSupplyCapacity(
        uint256 poolConfigration
    ) internal pure returns (uint256) {
        return (poolConfigration & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
    }

}