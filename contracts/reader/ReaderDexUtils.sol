// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/DataStore.sol";
//import "../data/Keys.sol";

import "../dex/DexStoreUtils.sol";
import "../dex/IDex.sol";

// @title ReaderPositionUtils
library ReaderDexUtils {
    //using WadRayMath for uint256;

    function _getDexPool(address dataStore, address underlyingAssetA, address underlyingAssetB) external view returns (address) {
        address dex = DexStoreUtils.get(dataStore, underlyingAssetA, underlyingAssetB);
        return IDex(dex).getPool();
    }   

    function _getDexPoolFeeAmount(address dataStore, address underlyingAssetA, address underlyingAssetB) external view returns (uint256) {
        address dex = DexStoreUtils.get(dataStore, underlyingAssetA, underlyingAssetB);
        return IDex(dex).getFeeAmount();
    } 

    function _getDexPoolSwapConstantFee(address dataStore, address underlyingAssetA, address underlyingAssetB, uint256 amountIn) external view returns (uint256) {
        address dex = DexStoreUtils.get(dataStore, underlyingAssetA, underlyingAssetB);
        return IDex(dex).getSwapFee(amountIn);
    }
}
