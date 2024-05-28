// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../pool/PoolUtils.sol";
import "../pool/PoolStoreUtils.sol";

/**
 * @title PoolTest
 * @dev Contract to help test the PoolUtils library
 */
contract PoolTest {
    function updatePool(
        address eventEmitter,
        address dataStore, 
        address underlyingAsset
    ) external {
        (   Pool.Props memory pool, 
            PoolCache.Props memory poolCache,,
        ) = PoolUtils.updatePoolAndCache(dataStore, underlyingAsset);

        PoolUtils.updateInterestRates(eventEmitter, pool, poolCache);

        PoolStoreUtils.set(
            dataStore, 
            underlyingAsset, 
            pool
        );
    }

    function getPool(
        address dataStore, 
        address underlyingAsset
    ) external view returns (Pool.Props memory) {
        Pool.Props memory pool = PoolStoreUtils.get(dataStore, underlyingAsset);
        return pool; 
    }

    function getPoolFeeFactor(
        address dataStore, 
        address underlyingAsset
    ) external view returns (uint256) {
        return PoolStoreUtils.getPoolFeeFactor(dataStore, underlyingAsset); 
    }
}
