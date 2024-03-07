// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

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

    function get(DataStore dataStore, bytes32 key) external view returns (Position.Props memory) {
        Position.Props memory position;
        if (!dataStore.containsBytes32(Keys.POSITION_LIST, key)) {
            return position;
        }

        position.setAccount(dataStore.getAddress(
            keccak256(abi.encode(key, ACCOUNT))
        ));

        position.setCollateralAndDebtPools(dataStore.getUint(
            keccak256(abi.encode(key, COLLATERAL_AND_DEBT_POOLS))
        ));

        return position;
    }

    function set(DataStore dataStore, bytes32 key, Position.Props memory position) external {
        dataStore.addBytes32(
            Keys.POSITION_LIST,
            key
        );

        dataStore.addBytes32(
            Keys.accountPositionListKey(position.account()),
            key
        );

        dataStore.setAddress(
            keccak256(abi.encode(key, ACCOUNT)),
            position.account()
        );

        dataStore.setUint(
            keccak256(abi.encode(key, COLLATERAL_AND_DEBT_POOLS)),
            position.collateralAndDebtPools()
        );

    }

    function remove(DataStore dataStore, bytes32 key, address account) external {
        if (!dataStore.containsBytes32(Keys.POSITION_LIST, key)) {
            revert Errors.PositionNotFound(key);
        }

        dataStore.removeBytes32(
            Keys.POSITION_LIST,
            key
        );

        dataStore.removeBytes32(
            Keys.accountPositionListKey(account),
            key
        );

        dataStore.removeAddress(
            keccak256(abi.encode(key, ACCOUNT))
        );

        dataStore.removeUint(
            keccak256(abi.encode(key, COLLATERAL_AND_DEBT_POOLS))
        );

    }

    function getPositionCount(DataStore dataStore) internal view returns (uint256) {
        return dataStore.getBytes32Count(Keys.POSITION_LIST);
    }

    function getPositionKeys(DataStore dataStore, uint256 start, uint256 end) internal view returns (bytes32[] memory) {
        return dataStore.getBytes32ValuesAt(Keys.POSITION_LIST, start, end);
    }

    function getAccountPositionCount(DataStore dataStore, address account) internal view returns (uint256) {
        return dataStore.getBytes32Count(Keys.accountPositionListKey(account));
    }

    function getAccountPositionKeys(DataStore dataStore, address account, uint256 start, uint256 end) internal view returns (bytes32[] memory) {
        return dataStore.getBytes32ValuesAt(Keys.accountPositionListKey(account), start, end);
    }
}