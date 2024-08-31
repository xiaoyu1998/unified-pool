
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../dex/DexStoreUtils.sol";

/**
 * @title DexStoreUtilsTest
 * @dev Contract to help test the DexStoreUtils library
 */
contract DexStoreUtilsTest {
    function getEmptyDex() external pure returns (address) {
        return address(0);
    }

    function setDex(address dataStore, address underlyingAssetA, address underlyingAssetB, address dex) external {
        DexStoreUtils.set(dataStore, underlyingAssetA, underlyingAssetB, dex);
    }

    function removeDex(address dataStore, address underlyingAssetA, address underlyingAssetB) external {
        DexStoreUtils.remove(dataStore, underlyingAssetA, underlyingAssetB);
    }
}
