// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../position/PositionUtils.sol";

/**
 * @title PositionTest
 * @dev Contract to help test the PositionUtils library
 */
contract PositionTest {
    function longPosition(
          Position.Props memory position,
          uint256 price,
          uint256 amount,
          bool isNewPriceAccToEntryPrice
    ) external pure returns (Position.Props memory) {
        PositionUtils.longPosition(
            position, 
            price, 
            amount, 
            isNewPriceAccToEntryPrice
        );

        return position; 
    }

    function shortPosition(
          Position.Props memory position,
          uint256 price,
          uint256 amount,
          bool isNewPriceAccToEntryPrice
    ) external pure returns (Position.Props memory) {
        PositionUtils.shortPosition(
            position, 
            price, 
            amount, 
            isNewPriceAccToEntryPrice
        );

        return position; 
    }
}
