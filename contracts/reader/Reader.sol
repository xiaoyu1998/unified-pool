// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/Keys.sol";

import "../pool/PoolStoreUtils.sol";
import "../pool/Pool.sol";

import "../position/PositionStoreUtils.sol";
import "../position/Position.sol";

import "../oracle/OracleStoreUtils.sol";


// @title Reader
// @dev Library for read functions
contract Reader {
    using SafeCast for uint256;
    using Position for Position.Props;

    function getPool(DataStore dataStore, address key) external view returns (Pool.Props memory) {
        return PoolStoreUtils.get(dataStore, key);
    }

    function getPools(DataStore dataStore, uint256 start, uint256 end) external view returns (Pool.Props[] memory) {
        address[] memory poolKeys = PoolStoreUtils.getPoolKeys(dataStore, start, end);
        Pool.Props[] memory pools = new Pool.Props[](poolKeys.length);
        for (uint256 i; i < poolKeys.length; i++) {
            address poolKey = poolKeys[i];
            Pool.Props memory pool = PoolStoreUtils.get(dataStore, poolKey);
            pools[i] = pool;
        }

        return pools;
    }

    function getPosition(DataStore dataStore, bytes32 key) external view returns (Position.Props memory) {
        return PositionStoreUtils.get(dataStore, key);
    }

    function getPositions(DataStore dataStore, address account) external view returns (Position.Props[] memory) {
        uint256 positionCount = PositionStoreUtils.getAccountPositionCount(dataStore, account);
        bytes32[] memory positionKeys = PositionStoreUtils.getAccountPositionKeys(dataStore, account, 0, positionCount);
        Position.Props[] memory positions = new Position.Props[](positionKeys.length);
        for (uint256 i; i < positionKeys.length; i++) {
            bytes32 positionKey = positionKeys[i];
            Position.Props memory position = PositionStoreUtils.get(dataStore, positionKey);
            positions[i] = position;
        }

        return positions;
    }

    function getOracle(DataStore dataStore, address underlyingAsset) external view returns (address) {
        return OracleStoreUtils.get(dataStore, underlyingAsset);
    }

    function getOracleDecimals(DataStore dataStore, address underlyingAsset) external view returns (uint256) {
        return OracleStoreUtils.getOracleDecimals(dataStore, underlyingAsset);
    }

}
