// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/IDataStore.sol";
import "../data/Keys.sol";
import "../error/Errors.sol";

// @title OracleStoreUtils
library OracleStoreUtils {
    // Maximum OracleDecimals
    uint256 internal constant MAX_ORACLE_DECIMALS = 1e30;

    function get(address dataStore, address underlyingAsset) public view returns (address) {
        return IDataStore(dataStore).getAddress(Keys.oracleKey(underlyingAsset));
    }

    function set(address dataStore, address underlyingAsset, address oracle) external {
        if (underlyingAsset == address(0)) {
            revert Errors.EmptyUnderlyingAsset();
        }

        if (oracle == address(0)) {
            revert Errors.EmptyOracle();
        }

        IDataStore(dataStore).setAddress(
            Keys.oracleKey(underlyingAsset),
            oracle
        );
    }

    function getOracleDecimals(address dataStore, address underlyingAsset) public view returns (uint256) {
        return IDataStore(dataStore).getUint(Keys.oracleDecimalsKey(underlyingAsset));
    }

    function setOracleDecimals(address dataStore, address underlyingAsset, uint256 oracleDecimals) external {
        if (underlyingAsset == address(0)) {
            revert Errors.EmptyUnderlyingAsset();
        }

        if (oracleDecimals > MAX_ORACLE_DECIMALS) {
            revert Errors.InvalidOracleDecimals(oracleDecimals, MAX_ORACLE_DECIMALS);
        }

        IDataStore(dataStore).setUint(
            Keys.oracleDecimalsKey(underlyingAsset),
            oracleDecimals
        );
    }
    
}
