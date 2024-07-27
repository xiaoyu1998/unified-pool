// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/IDataStore.sol";
import "../data/Keys.sol";
import "../error/Errors.sol";

// @title OracleStoreUtils
library FeeStoreUtils {
    // Maximum OracleDecimals
    uint256 internal constant MAX_ORACLE_DECIMALS = 1e30;

    function getTreasury(address dataStore) public view returns (address) {
        return IDataStore(dataStore).getAddress(Keys.TREASURY);
    }

    function setTreasury(address dataStore, address treasury) external {
        if (treasury == address(0)) {
            revert Errors.EmptyTreasury();
        }
        IDataStore(dataStore).setAddress(
            Keys.TREASURY,
            treasury
        );
    }
    
}
