// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

// import "../data/DataStore.sol";
import "../data/IDataStore.sol";
import "../data/Keys.sol";

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
    
}
