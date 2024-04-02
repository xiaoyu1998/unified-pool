// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/DataStore.sol";
import "../data/Keys.sol";

// @title OracleStoreUtils
library OracleStoreUtils {

    function get(DataStore dataStore, address underlyingAsset) public view returns (address) {
        return dataStore.getAddress(Keys.oracleKey(underlyingAsset));
    }

    function set(DataStore dataStore, address underlyingAsset, address oracle) external {
         dataStore.setAddress(
            Keys.oracleKey(underlyingAsset),
            oracle
        );
    }

    function getOracleDecimals(DataStore dataStore, address underlyingAsset) public view returns (uint256) {
        return dataStore.getUint(Keys.oracleDecimalsKey(underlyingAsset));
    }

    function setOracleDecimals(DataStore dataStore, address underlyingAsset, uint256 oracle) external {
         dataStore.setUint(
            Keys.oracleDecimalsKey(underlyingAsset),
            oracle
        );
    }
    
}
