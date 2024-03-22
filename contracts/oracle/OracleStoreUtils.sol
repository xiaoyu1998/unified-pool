// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/DataStore.sol";
import "../data/Keys.sol";

// @title OracleStoreUtils
library OracleStoreUtils {

    function get(DataStore dataStore) public view returns (address) {
        return dataStore.getAddress(
            keccak256(abi.encode(Keys.ORACLE))
        );
    }

    function set(DataStore dataStore, address oracle) external {
         dataStore.setAddress(
            Keys.ORACLE,
            oracle
        );
    }
    
}
