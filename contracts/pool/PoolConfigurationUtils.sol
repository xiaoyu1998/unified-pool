// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;

// @title PoolUtils
// @dev Library for Pool functions
library PoolConfigurationUtils {
  uint256 internal constant RESERVE_FEE_MASK =            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF;
  uint256 internal constant RESERVE_FACTOR_START_BIT_POSITION = 64;
  uint256 internal constant MAX_VALID_FEE_FACTOR = 65535;

  /**
   * @notice Sets the fee factor of the fee
   * @param poolConfigration The fee configuration
   * @param feeFactor The fee factor
   */
  function setFeeFactor(
    uint256 poolConfigration,
    uint256 feeFactor
  ) internal returns (uint256) {
    require(feeFactor <= MAX_VALID_FEE_FACTOR, Errors.INVALID_RESERVE_FACTOR);

    poolConfigration =
      (poolConfigration & RESERVE_FACTOR_MASK) |
      (feeFactor << RESERVE_FACTOR_START_BIT_POSITION);

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
    return (poolConfigration & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
  }

}