// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.24;
import "../pool/PoolConfigurationUtils.sol";

library Position {

    struct Props {
        address account;
        uint256 collateralAndDebtPools;
    }

    uint256 internal constant BORROWING_MASK =
        0x5555555555555555555555555555555555555555555555555555555555555555;
    uint256 internal constant COLLATERAL_MASK =
        0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;


    function account(Props memory props) internal pure returns (address) {
        return props.addresses.account;
    }

    function setAccount(Props memory props, address value) internal pure {
        props.account = value;
    }

    function collateralAndDebtPools(Props memory props) internal pure returns (uint256) {
        return props.collateralAndDebtPools;
    }

    function setCollateralAndDebtPools(Props memory props, uint256 value) internal pure {
        props.collateralAndDebtPools = value;
    }

    function setPoolAsBorrowing(
        Props memory props, 
        uint256 id, 
        bool borrowing
    ) internal pure {
        unchecked {
            require(poolKeyId < PoolConfigurationUtils.MAX_POOL_COUNT, Errors.INVALID_POOL_INDEX);
            uint256 bit = 1 << ((poolKeyId << 1));
            if (borrowing) {
                props.collateralAndDebtPools |= bit;
            } else {
                props.collateralAndDebtPools &= ~bit;
            }
        }
    }

    function setPoolAsCollateral(
        Props memory props, 
        uint256 poolKeyId, 
        bool usingAsCollateral
    ) internal pure {
        unchecked {
            require(poolKeyId < PoolConfigurationUtils.MAX_POOL_COUNT, Errors.INVALID_POOL_INDEX);
            uint256 bit = 1 << ((poolKeyId << 1) + 1);
            if (usingAsCollateral) {
                props.collateralAndDebtPools |= bit;
            } else {
                props.collateralAndDebtPools &= ~bit;
            }
        }
    }

    /**
    * @notice Returns if a user has been using the pool for borrowing or as collateral
    * @param self The configuration object
    * @param poolKeyId The index of the pool in the bitmap
    * @return True if the user has been using a pool for borrowing or as collateral, false otherwise
    */
    function isUsingAsCollateralOrBorrowing(
        Props memory props,
        uint256 poolKeyId
    ) internal pure returns (bool) {
        unchecked {
            require(poolKeyId < PoolConfigurationUtils.MAX_POOLS_COUNT, Errors.INVALID_POOL_INDEX);
            return (props.collateralAndDebtPools >> (poolKeyId << 1)) & 3 != 0;
        }
    }

    /**
    * @notice Validate a user has been using the pool for borrowing
    * @param self The configuration object
    * @param poolKeyId The index of the pool in the bitmap
    * @return True if the user has been using a pool for borrowing, false otherwise
    */
    function isBorrowing(
        Props memory props,
        uint256 poolKeyId
    ) internal pure returns (bool) {
        unchecked {
            require(poolKeyId < PoolConfigurationUtils.MAX_POOLS_COUNT, Errors.INVALID_POOL_INDEX);
            return (props.collateralAndDebtPools >> (poolKeyId << 1)) & 1 != 0;
        }
    }

    /**
    * @notice Validate a user has been using the pool as collateral
    * @param self The configuration object
    * @param poolKeyId The index of the pool in the bitmap
    * @return True if the user has been using a pool as collateral, false otherwise
    */
    function isUsingAsCollateral(
        Props memory props,
        uint256 poolKeyId
    ) internal pure returns (bool) {
        unchecked {
            require(poolKeyId < PoolConfigurationUtils.MAX_POOLS_COUNT, Errors.INVALID_POOL_INDEX);
            return (props.collateralAndDebtPools >> ((poolKeyId << 1) + 1)) & 1 != 0;
        }
    }


}
