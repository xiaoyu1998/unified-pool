// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/IDataStore.sol";
import "../data/Keys.sol";
import "../error/Errors.sol";

// @title DexStoreUtils
library DexStoreUtils {

    function get(address dataStore, address underlyingAssetA, address underlyingAssetB) public view returns (address) {

        bytes32 key = Keys.dexKey(underlyingAssetA, underlyingAssetB);
        if (!IDataStore(dataStore).containsBytes32(Keys.DEX_LIST, key)) {
            return address(0);
        }    
        return IDataStore(dataStore).getAddress(key);
    }

    function set(address dataStore, address underlyingAssetA, address underlyingAssetB, address dex) external {
        if (underlyingAssetA == address(0) || underlyingAssetB == address(0)) {
            revert Errors.EmptyUnderlyingAsset();
        }

        if (dex == address(0)) {
            revert Errors.EmptyDex();
        }

        bytes32 key = Keys.dexKey(underlyingAssetA, underlyingAssetB);

        IDataStore(dataStore).addBytes32(
            Keys.DEX_LIST,
            key
        );

        IDataStore(dataStore).setAddress(key, dex);
    }
}
