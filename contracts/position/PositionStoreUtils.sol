// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/Keys.sol";
import "../data/DataStore.sol";

import "./Position.sol";

/**
 * @title PositionStoreUtils
 * @dev Library for position storage functions
 */
library PositionStoreUtils {
    using Position for Position.Props;

    bytes32 public constant ACCOUNT = keccak256(abi.encode("ACCOUNT"));
    bytes32 public constant COLLATERAL_AND_DEBT_POOLS = keccak256(abi.encode("COLLATERAL_AND_DEBT_POOLS"));

    function get(DataStore dataStore, address key) external view returns (Position.Props memory) {
        Position.Props memory position;
        if (!dataStore.containsAddress(Keys.POSITION_LIST, key)) {
            return position;
        }

        position.account = dataStore.getAddress(
            keccak256(abi.encode(key, ACCOUNT))
        );

        position.collateralAndDebtPools = dataStore.getUint(
            keccak256(abi.encode(key, COLLATERAL_AND_DEBT_POOLS))
        );

        return position;
    }

    function set(DataStore dataStore, address key, Position.Props memory position) external {
        dataStore.addAddress(
            Keys.POSITION_LIST,
            key
        );

        // dataStore.addBytes32(
        //     Keys.accountPositionListKey(position.account()),
        //     key
        // );

        dataStore.setAddress(
            keccak256(abi.encode(key, ACCOUNT)),
            position.account
        );

        dataStore.setUint(
            keccak256(abi.encode(key, COLLATERAL_AND_DEBT_POOLS)),
            position.collateralAndDebtPools
        );

    }

    function remove(DataStore dataStore, address key) external {
        if (!dataStore.containsAddress(Keys.POSITION_LIST, key)) {
            revert Errors.PositionNotFound(key);
        }

        dataStore.removeAddress(
            Keys.POSITION_LIST,
            key
        );

        // dataStore.removeBytes32(
        //     Keys.accountPositionListKey(account),
        //     key
        // );

        dataStore.removeAddress(
            keccak256(abi.encode(key, ACCOUNT))
        );

        dataStore.removeUint(
            keccak256(abi.encode(key, COLLATERAL_AND_DEBT_POOLS))
        );

    }

    function getPositionCount(DataStore dataStore) internal view returns (uint256) {
        return dataStore.getAddressCount(Keys.POSITION_LIST);
    }

    function getPositionKeys(DataStore dataStore, uint256 start, uint256 end) internal view returns (address[] memory) {
        return dataStore.getAddressValuesAt(Keys.POSITION_LIST, start, end);
    }

    // function getAccountPositionCount(DataStore dataStore, address account) internal view returns (uint256) {
    //     return dataStore.getBytes32Count(Keys.accountPositionListKey(account));
    // }

    // function getAccountPositionKeys(DataStore dataStore, address account, uint256 start, uint256 end) internal view returns (bytes32[] memory) {
    //     return dataStore.getBytes32ValuesAt(Keys.accountPositionListKey(account), start, end);
    // }
}