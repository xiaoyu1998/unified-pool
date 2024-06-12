// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/IDataStore.sol";
import "../data/Keys.sol";

import "../pool/PoolConfigurationUtils.sol";
import "../pool/PoolStoreUtils.sol";

// @title ConfigStoreUtils
// @dev Library for config store utils functions, to help with the getting of configurations
library ConfigStoreUtils {

    function getPoolDecimals(address dataStore, address underlyingAsset ) public view returns (uint256) {
        uint256 configuration = PoolStoreUtils.getConfiguration(dataStore, underlyingAsset);
        return PoolConfigurationUtils.getDecimals(configuration);
    }

    function getPoolFeeFactor(address dataStore, address underlyingAsset ) public view returns (uint256) {
        uint256 configuration = PoolStoreUtils.getConfiguration(dataStore, underlyingAsset);
        return PoolConfigurationUtils.getFeeFactor(configuration);
    }

    function getPoolBorrowCapacity(address dataStore, address underlyingAsset ) public view returns (uint256) {
        uint256 configuration = PoolStoreUtils.getConfiguration(dataStore, underlyingAsset);
        return PoolConfigurationUtils.getBorrowCapacity(configuration);
    }

    function getPoolSupplyCapacity(address dataStore, address underlyingAsset ) public view returns (uint256) {
        uint256 configuration = PoolStoreUtils.getConfiguration(dataStore, underlyingAsset);
        return PoolConfigurationUtils.getSupplyCapacity(configuration);
    }

    function getPoolActive(address dataStore, address underlyingAsset ) public view returns (bool) {
        uint256 configuration = PoolStoreUtils.getConfiguration(dataStore, underlyingAsset);
        return PoolConfigurationUtils.getActive(configuration);
    }

    function getPoolFrozen(address dataStore, address underlyingAsset ) public view returns (bool) {
        uint256 configuration = PoolStoreUtils.getConfiguration(dataStore, underlyingAsset);
        return PoolConfigurationUtils.getFrozen(configuration);
    }

    function getPoolPaused(address dataStore, address underlyingAsset ) public view returns (bool) {
        uint256 configuration = PoolStoreUtils.getConfiguration(dataStore, underlyingAsset);
        return PoolConfigurationUtils.getPaused(configuration);
    }

    function getPoolUsd(address dataStore, address underlyingAsset ) public view returns (bool) {
        uint256 configuration = PoolStoreUtils.getConfiguration(dataStore, underlyingAsset);
        return PoolConfigurationUtils.getUsd(configuration);
    }

    function getPoolBorrowingEnabled(address dataStore, address underlyingAsset ) public view returns (bool) {
        uint256 configuration = PoolStoreUtils.getConfiguration(dataStore, underlyingAsset);
        return PoolConfigurationUtils.getBorrowingEnabled(configuration);
    }
    
}
