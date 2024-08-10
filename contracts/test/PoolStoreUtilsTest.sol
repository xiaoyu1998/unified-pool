
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../pool/PoolStoreUtils.sol";

/**
 * @title PoolStoreUtilsTest
 * @dev Contract to help test the PoolStoreUtils library
 */
contract PoolStoreUtilsTest {
    function getEmptyPool() external pure returns (Pool.Props memory) {
        Pool.Props memory pool;
        return pool;
    }

    function setPool(address dataStore, address key, Pool.Props memory pool) external {
        PoolStoreUtils.set(dataStore, key, pool);
    }

    function removePool(address dataStore, address key) external {
        PoolStoreUtils.remove(dataStore, key);
    }
}
