// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/DataStore.sol";
//import "../data/Keys.sol";

import "../dex/DexStoreUtils.sol";
// import "../dex/IDex.sol";
import "../dex/IDex2.sol";

// @title ReaderPositionUtils
library ReaderDexUtils {

    function _getDexPool(address dataStore, address underlyingAssetA, address underlyingAssetB) external view returns (address) {
        address dex = DexStoreUtils.get(dataStore, underlyingAssetA, underlyingAssetB);
        return IDex2(dex).getPool(underlyingAssetA, underlyingAssetB);
    }   

    function _getDexPoolFeeAmount(address dataStore, address underlyingAssetA, address underlyingAssetB) external view returns (uint256) {
        address dex = DexStoreUtils.get(dataStore, underlyingAssetA, underlyingAssetB);
        return IDex2(dex).getFeeAmount();
    } 

    function _getDexPoolSwapConstantFee(address dataStore, address underlyingAssetA, address underlyingAssetB, uint256 amountIn) external view returns (uint256) {
        address dex = DexStoreUtils.get(dataStore, underlyingAssetA, underlyingAssetB);
        return IDex2(dex).getSwapFee(amountIn);
    }

    function _getDexs(address dataStore) external view returns (DexStoreUtils.Dex[] memory) {
        return DexStoreUtils.getDexs(dataStore);
    }

    function _getDex(address dataStore, address underlyingAssetA, address underlyingAssetB) external view returns (address) {
        return DexStoreUtils.get(dataStore, underlyingAssetA, underlyingAssetB);
    }

}
