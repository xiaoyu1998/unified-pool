// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

// import "../data/DataStore.sol";
import "../data/IDataStore.sol";
import "../data/Keys.sol";

import "../pool/PoolConfigurationUtils.sol";
import "../pool/PoolStoreUtils.sol";

// @title ConfigStoreUtils
// @dev Library for deposit functions, to help with the depositing of liquidity
// into a pool in return for pool tokens
library ConfigStoreUtils {

    function getHealthFactorCollateralRateThreshold(address dataStore, address underlyingAsset) public view returns (uint256) {
        return IDataStore(dataStore).getUint(Keys.healthFactorCollateralRateThresholdKey(underlyingAsset));
    }

    function getDebtMultiplierFactorForRedeem(address dataStore) public view returns (uint256) {
        return IDataStore(dataStore).getUint(Keys.DEBT_MULTIPLIER_FACTOR_FOR_REDEEM);
    }

    function getHealthFactorLiquidationThreshold(address dataStore) public view returns (uint256) {
        return IDataStore(dataStore).getUint(Keys.HEALTH_FACTOR_LIQUIDATION_THRESHOLD);
    }

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
    
}
