// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/IDataStore.sol";
import "../data/Keys.sol";
import "../error/Errors.sol";

// @title DexStoreUtils
library DexStoreUtils {

    function get(
        address dataStore, 
        address underlyingAssetA, 
        address underlyingAssetB
    ) public view returns (address) {
        bytes32 key = Keys.dexKey(underlyingAssetA, underlyingAssetB);
        if (!IDataStore(dataStore).containsBytes32(Keys.DEX_LIST, key)) {
            return address(0);
        }    
        return IDataStore(dataStore).getAddress(key);
    }

    function get(
        address dataStore, 
        bytes32 key
    ) public view returns (address) {
        if (!IDataStore(dataStore).containsBytes32(Keys.DEX_LIST, key)) {
            return address(0);
        }    
        return IDataStore(dataStore).getAddress(key);
    }

    function set(
        address dataStore, 
        address underlyingAssetA, 
        address underlyingAssetB, 
        address dex
    ) external {
        if (underlyingAssetA == address(0) || underlyingAssetB == address(0)) {
            revert Errors.EmptyUnderlyingAsset();
        }

        if (dex == address(0)) {
            revert Errors.EmptyDex();
        }

        bytes32 key = Keys.dexKey(underlyingAssetA, underlyingAssetB);
        IDataStore(dataStore).addBytes32(Keys.DEX_LIST, key);
        IDataStore(dataStore).setAddress(key, dex);
    }

    function remove(
        address dataStore, 
        address underlyingAssetA, 
        address underlyingAssetB
    ) external {
        if (underlyingAssetA == address(0) || underlyingAssetB == address(0)) {
            revert Errors.EmptyUnderlyingAsset();
        }
        bytes32 key = Keys.dexKey(underlyingAssetA, underlyingAssetB);
        if (!IDataStore(dataStore).containsBytes32(Keys.DEX_LIST, key)) {
            revert Errors.EmptyDex();
        }
        IDataStore(dataStore).removeBytes32(Keys.DEX_LIST, key);
        IDataStore(dataStore).removeAddress(key);
    }

    struct Dex {
        bytes32 key;
        address dex;
    }

    function getDexs(address dataStore) internal view returns (Dex[] memory) {
        uint256 dexCount = IDataStore(dataStore).getBytes32Count(Keys.DEX_LIST);
        bytes32[] memory dexKeys = IDataStore(dataStore).getBytes32ValuesAt(Keys.DEX_LIST, 0, dexCount);
        Dex[] memory dexs = new Dex[](dexKeys.length);
        for (uint256 i; i < dexKeys.length; i++) {
            dexs[i].key = dexKeys[i];
            dexs[i].dex = get(dataStore, dexKeys[i]);
        }
        return dexs;
    }

}
