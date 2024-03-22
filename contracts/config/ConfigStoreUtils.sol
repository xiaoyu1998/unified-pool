// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/DataStore.sol";
import "../data/Keys.sol";

// @title ConfigStoreUtils
// @dev Library for deposit functions, to help with the depositing of liquidity
// into a pool in return for pool tokens
library ConfigStoreUtils {

    function getHealthFactorCollateralRateThreshold(DataStore dataStore) public view returns (address) {
        return dataStore.getUint(Keys.HEALTH_FACTOR_COLLATERAL_RATE_THRESHOLD);
    }
    
}
