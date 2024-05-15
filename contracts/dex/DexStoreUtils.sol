// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/IDataStore.sol";
import "../data/Keys.sol";
import "../error/Errors.sol";

// @title DexStoreUtils
library DexStoreUtils {

    function get(address dataStore, address underlyingAssetA, address underlyingAssetB) public view returns (address) {
        return IDataStore(dataStore).getAddress(Keys.dexKey(underlyingAssetA, underlyingAssetB));
    }

    function set(address dataStore, address underlyingAssetA, address underlyingAssetB, address dex) external {
        if (underlyingAssetA == address(0) || underlyingAssetB == address(0)) {
            revert Errors.UnderlyAssetEmpty();
        }

        if (dex == address(0)) {
            revert Errors.DexEmpty();
        }

        IDataStore(dataStore).setAddress(
            Keys.dexKey(underlyingAssetA, underlyingAssetB),
            dex
        );
    }
}
