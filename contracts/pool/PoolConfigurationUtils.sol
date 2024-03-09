// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

  // struct PoolConfiguration {
  //   //bit 0-15: LTV
  //   //bit 16-31: Liq. threshold
  //   //bit 32-47: Liq. bonus
  //   //bit 48-55: Decimals
  //   //bit 56: reserve is active
  //   //bit 57: reserve is frozen
  //   //bit 58: borrowing is enabled
  //   //bit 59: stable rate borrowing enabled
  //   //bit 60: asset is paused
  //   //bit 61: borrowing in isolation mode is enabled
  //   //bit 62: siloed borrowing enabled
  //   //bit 63: flashloaning enabled
  //   //bit 64-79: reserve factor
  //   //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
  //   //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
  //   //bit 152-167 liquidation protocol fee
  //   //bit 168-175 eMode category
  //   //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
  //   //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
  //   //bit 252-255 unused
  //   uint256 data;
  // }


// @title PoolUtils
// @dev Library for Pool functions
library PoolConfigurationUtils {
    uint256 internal constant DECIMALS_MASK =                  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant ACTIVE_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant FROZEN_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant BORROWING_MASK =                 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant PAUSED_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF; // prettier-ignore  
    uint256 internal constant POOL_FEE_MASK =                  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF;
    uint256 internal constant BORROW_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant SUPPLY_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    
    uint256 internal constant POOL_DECIMALS_START_BIT_POSITION = 48;
    uint256 internal constant IS_ACTIVE_START_BIT_POSITION = 56;
    uint256 internal constant IS_FROZEN_START_BIT_POSITION = 57;
    uint256 internal constant BORROWING_ENABLED_START_BIT_POSITION = 58;
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
      /**
       * @notice Gets the configuration flags of the reserve
       * @param self The reserve configuration
       * @return The state flag representing active
       * @return The state flag representing frozen
       * @return The state flag representing borrowing enabled
       * @return The state flag representing paused
       */
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

    /**
       * @notice Sets the active state of the reserve
       * @param self The reserve configuration
       * @param active The active state
       */
      function setActive(uint256 poolConfigration, bool active) internal pure {
          poolConfigration =
              (poolConfigration & ACTIVE_MASK) |
              (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);

          return poolConfigration;
      }

      /**
       * @notice Gets the active state of the reserve
       * @param self The reserve configuration
       * @return The active state
       */
      function getActive(uint256 poolConfigration) internal pure returns (bool) {
          return (poolConfigration & ~ACTIVE_MASK) != 0;
      }

      /**
       * @notice Sets the frozen state of the reserve
       * @param self The reserve configuration
       * @param frozen The frozen state
       */
      function setFrozen(uint256 poolConfigration, bool frozen) internal pure {
          poolConfigration =
              (poolConfigration & FROZEN_MASK) |
              (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);

          return poolConfigration;
      }

      /**
       * @notice Gets the frozen state of the reserve
       * @param self The reserve configuration
       * @return The frozen state
       */
      function getFrozen(uint256 poolConfigration) internal pure returns (bool) {
          return (poolConfigration & ~FROZEN_MASK) != 0;
      }

      /**
       * @notice Sets the paused state of the reserve
       * @param self The reserve configuration
       * @param paused The paused state
       */
      function setPaused(
          uint256 poolConfigration, 
          bool paused
      ) internal pure {
          poolConfigration =
              (poolConfigration & PAUSED_MASK) |
              (uint256(paused ? 1 : 0) << IS_PAUSED_START_BIT_POSITION);

          return poolConfigration;
      }

      /**
       * @notice Gets the paused state of the reserve
       * @param self The reserve configuration
       * @return The paused state
       */
      function getPaused(
          uint256 poolConfigration
      ) internal pure returns (bool) {
          return (poolConfigration & ~PAUSED_MASK) != 0;
      }


    /**
     * @notice Sets the decimals of the underlying asset of the reserve
     * @param self The reserve configuration
     * @param decimals The decimals
     */
    function setDecimals(
        uint256 poolConfigration,
        uint256 decimals
    ) internal pure {
        require(decimals <= MAX_VALID_DECIMALS, Errors.INVALID_DECIMALS);

        poolConfigration = (poolConfigration & DECIMALS_MASK) | (decimals << POOL_DECIMALS_START_BIT_POSITION);
        return poolConfigration;
    }

    /**
     * @notice Gets the decimals of the underlying asset of the reserve
     * @param self The reserve configuration
     * @return The decimals of the asset
     */
    function getDecimals(
        uint256 poolConfigration
    ) internal pure returns (uint256) {
        return (poolConfigration & ~DECIMALS_MASK) >> POOL_DECIMALS_START_BIT_POSITION;
    }



    /**
     * @notice Sets the fee factor of the fee
     * @param poolConfigration The fee configuration
     * @param feeFactor The fee factor
     */
    function setFeeFactor(
        uint256 poolConfigration,
        uint256 feeFactor
    ) internal returns (uint256) {
        require(feeFactor <= MAX_VALID_FEE_FACTOR, Errors.INVALID_POOL_FACTOR);

        poolConfigration =
          (poolConfigration & POOL_FACTOR_MASK) |
          (feeFactor << POOL_FACTOR_START_BIT_POSITION);

        return poolConfigration;
    }

    /**
     * @notice Gets the fee factor of the pool
     * @param self The reserve configuration
     * @return The reserve factor
     */
    function getFeeFactor(
        uint256 poolConfigration,
    ) internal pure returns (uint256) {
        return (poolConfigration & ~POOL_FACTOR_MASK) >> POOL_FACTOR_START_BIT_POSITION;
    }

    /**
     * @notice Sets the borrow cap of the reserve
     * @param self The reserve configuration
     * @param borrowCapacity The borrow cap
     */
    function setBorrowCapacity(
        uint256 poolConfigration,
        uint256 borrowCapacity
    ) internal pure {
        require(borrowCapacity <= MAX_VALID_BORROW_CAP, Errors.INVALID_BORROW_CAP);

        poolConfigration= (poolConfigration & BORROW_CAP_MASK) | (borrowCapacity << BORROW_CAP_START_BIT_POSITION);
        return poolConfigration;
    }

    /**
     * @notice Gets the borrow cap of the reserve
     * @param self The reserve configuration
     * @return The borrow cap
     */
    function getBorrowCapacity(
        uint256 poolConfigration
    ) internal pure returns (uint256) {
        return (self.data & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
    }

    /**
     * @notice Sets the supply cap of the reserve
     * @param self The reserve configuration
     * @param supplyCapacity The supply cap
     */
    function setSupplyCapacity(
        uint256 poolConfigration,
        uint256 supplyCapacity
    ) internal pure {
        require(supplyCapacity <= MAX_VALID_SUPPLY_CAP, Errors.INVALID_SUPPLY_CAP);

        poolConfigration = (poolConfigration & SUPPLY_CAP_MASK) | (poolConfigration << SUPPLY_CAP_START_BIT_POSITION);
        return poolConfigration;
    }

    /**
     * @notice Gets the supply cap of the reserve
     * @param self The reserve configuration
     * @return The supply cap
     */
    function getSupplyCapacity(
        uint256 poolConfigration
    ) internal pure returns (uint256) {
        return (poolConfigration & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
    }

}