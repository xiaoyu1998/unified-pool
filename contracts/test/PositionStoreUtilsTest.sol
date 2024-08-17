
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../position/PositionStoreUtils.sol";

/**
 * @title PositionStoreUtilsTest
 * @dev Contract to help test the PositionStoreUtils library
 */
contract PositionStoreUtilsTest {
    function getEmptyPosition() external pure returns (Position.Props memory) {
        Position.Props memory position;
        return position;
    }

    function setPosition(address dataStore, bytes32 key, Position.Props memory position) external {
        PositionStoreUtils.set(dataStore, key, position);
    }

    function removePosition(address dataStore, bytes32 key, address account) external {
        PositionStoreUtils.remove(dataStore, key, account);
    }
}
