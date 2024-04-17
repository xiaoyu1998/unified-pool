// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../data/DataStore.sol";
import "../data/Keys.sol";
import "../error/Errors.sol";

import "./OracleStoreUtils.sol";
import "./IPriceFeed.sol";
import "../utils/WadRayMath.sol";

// @title OracleUtils
library OracleUtils {
    using WadRayMath for uint256;

    function getPrice(address dataStore, address underlyingAsset) public view returns (uint256) {
        address oracle = OracleStoreUtils.get(dataStore, underlyingAsset);
        if (oracle == address(0)) {
            revert Errors.EmptyOracle(underlyingAsset);
        }

        IPriceFeed priceFeed = IPriceFeed(oracle);
        (
            /* uint80 roundID */,
            int256 _price,
            /* uint256 startedAt */,
            uint256 timestamp,
            /* uint80 answeredInRound */
         ) = priceFeed.latestRoundData();

        if (_price == 0){
            revert Errors.InvalidOraclePrice(underlyingAsset, _price);
        }

        uint256 price = SafeCast.toUint256(_price);
        uint256 decimals = OracleStoreUtils.getOracleDecimals(dataStore, underlyingAsset);
        uint256 adjustPrice = Math.mulDiv(price, WadRayMath.RAY, 10**decimals);
        // Printer.log("-----------------------getPrice------------------------");
        // Printer.log("price", price);
        // Printer.log("decimals", decimals);
        // Printer.log("adjustPrice", adjustPrice);
        return adjustPrice;
    }

    function calcPrice(
        uint256 amountIn, 
        uint256 decimalsIn, 
        uint256 amountOut, 
        uint256 decimalsOut,
        bool poolOutIsUsd
    ) public view returns (uint256) {

        uint256 amountUsd = amountIn;
        uint256 decimalsUsd = decimalsIn;
        uint256 amountOthers = amountOut;
        uint256 decimalsOthers = decimalsOut;
        if (poolOutIsUsd){ //poolIn must be Not usd
            uint256 tmp;
            tmp = amountUsd; amountUsd = amountOthers; amountOthers = tmp;
            tmp = decimalsUsd; decimalsUsd = decimalsOthers; decimalsOthers = tmp;
        }

        uint256 adjustAmountUsd = Math.mulDiv(amountUsd, WadRayMath.RAY, 10**decimalsIn);
        uint256 adjustAmountOthers = Math.mulDiv(amountOthers, WadRayMath.RAY, 10**decimalsOthers);

        return adjustAmountUsd.rayDiv(adjustAmountOthers);

    }
    
}
