// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../data/DataStore.sol";
import "../data/Keys.sol";

import "./OracleStoreUtils.sol";
import "./IPriceFeed.sol";
import "../utils/WadRayMath.sol";

// @title OracleStoreUtils
library OracleUtils {

    function getPrice(DataStore dataStore, address underlyingAsset) public view returns (uint256) {
        address oracle = OracleStoreUtils.get(dataStore, underlyingAsset);

        IPriceFeed priceFeed = IPriceFeed(oracle);
        (
            /* uint80 roundID */,
            int256 _price,
            /* uint256 startedAt */,
            uint256 timestamp,
            /* uint80 answeredInRound */
         ) = priceFeed.latestRoundData();

        uint256 price = SafeCast.toUint256(_price);
        uint256 decimals = OracleStoreUtils.getOracleDecimals(dataStore, underlyingAsset);
        uint256 adjustPrice = Math.mulDiv(price, WadRayMath.RAY, 10**decimals);
        // Printer.log("-----------------------getPrice------------------------");
        // Printer.log("price", price);
        // Printer.log("decimals", decimals);
        // Printer.log("adjustPrice", adjustPrice);
        return adjustPrice;
    }
    
}
