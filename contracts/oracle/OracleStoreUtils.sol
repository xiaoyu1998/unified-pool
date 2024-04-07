// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/IDataStore.sol";
import "../data/Keys.sol";

// @title OracleStoreUtils
library OracleStoreUtils {

    function get(address dataStore, address underlyingAsset) public view returns (address) {
        return IDataStore(dataStore).getAddress(Keys.oracleKey(underlyingAsset));
    }

    function set(address dataStore, address underlyingAsset, address oracle) external {
        IDataStore(dataStore).setAddress(
            Keys.oracleKey(underlyingAsset),
            oracle
        );
    }

    function getOracleDecimals(address dataStore, address underlyingAsset) public view returns (uint256) {
        return IDataStore(dataStore).getUint(Keys.oracleDecimalsKey(underlyingAsset));
    }

    function setOracleDecimals(address dataStore, address underlyingAsset, uint256 oracle) external {
         IDataStore(dataStore).setUint(
            Keys.oracleDecimalsKey(underlyingAsset),
            oracle
        );
    }
    
}
