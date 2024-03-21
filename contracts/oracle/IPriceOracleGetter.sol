// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// @title IPriceFeed
// @dev Interface for a price feed
interface IPriceOracleGetter {
    function getPrice(address underlyingAsset) external view returns (uint256);
}
