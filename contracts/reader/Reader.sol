// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/Keys.sol";

import "../pool/PoolStoreUtils.sol";
import "../pool/Pool.sol";

import "../position/PositionStoreUtils.sol";
import "../position/Position.sol";

//import "../oracle/OracleStoreUtils.sol";
import "../oracle/OracleUtils.sol";

import "./ReaderUtils.sol";


// @title Reader
// @dev Library for read functions
contract Reader {
    using SafeCast for uint256;
    using Position for Position.Props;

    function _getPool(DataStore dataStore, address poolKey) internal view returns (Pool.Props memory) {
        return PoolStoreUtils.get(dataStore, poolKey);
    }

    function _getPools(DataStore dataStore, uint256 start, uint256 end) internal view returns (Pool.Props[] memory) {
        address[] memory poolKeys = PoolStoreUtils.getPoolKeys(dataStore, start, end);
        Pool.Props[] memory pools = new Pool.Props[](poolKeys.length);
        for (uint256 i; i < poolKeys.length; i++) {
            address poolKey = poolKeys[i];
            Pool.Props memory pool = PoolStoreUtils.get(dataStore, poolKey);
            pools[i] = pool;
        }

        return pools;
    }

    function _getPosition(DataStore dataStore, bytes32 positionKey) internal view returns (Position.Props memory) {
        return PositionStoreUtils.get(dataStore, positionKey);
    }

    function _getPositions(DataStore dataStore, address account) internal view returns (Position.Props[] memory) {
        uint256 positionCount = PositionStoreUtils.getAccountPositionCount(dataStore, account);
        bytes32[] memory positionKeys = 
            PositionStoreUtils.getAccountPositionKeys(dataStore, account, 0, positionCount);
        Position.Props[] memory positions = 
            new Position.Props[](positionKeys.length);
        for (uint256 i; i < positionKeys.length; i++) {
            bytes32 positionKey = positionKeys[i];
            Position.Props memory position = PositionStoreUtils.get(dataStore, positionKey);
            positions[i] = position;
        }

        return positions;
    }

    function getPool(DataStore dataStore, address poolKey) external view returns (Pool.Props memory) {
        return _getPool(dataStore, poolKey);
    }

    function getPools(DataStore dataStore, uint256 start, uint256 end) external view returns (Pool.Props[] memory) {
        return _getPools(dataStore, start, end);
    }

    function getPosition(DataStore dataStore, bytes32 positionKey) external view returns (Position.Props memory) {
        return _getPosition(dataStore, positionKey);
    }

    function getPositions(DataStore dataStore, address account) external view returns (Position.Props[] memory) {
        return _getPositions(dataStore, account);
    }

    function getPoolsLiquidity(DataStore dataStore, uint256 start, uint256 end) external view returns (ReaderUtils.PoolLiquidity[] memory) {
        Pool.Props[] memory pools = _getPools(dataStore, start, end);
        ReaderUtils.PoolLiquidity[] memory poolsLiquidity = 
            new ReaderUtils.PoolLiquidity[](pools.length);
        for (uint256 i; i < pools.length; i++) {
            poolsLiquidity[i] = ReaderUtils.getPoolLiquidity(dataStore, pools[i].poolToken);
        }
        return poolsLiquidity;
    }

    function getPoolLiquidity(DataStore dataStore, address poolKey) external view returns (ReaderUtils.PoolLiquidity memory) {
        Pool.Props memory pool = _getPool(dataStore, poolKey);
        ReaderUtils.PoolLiquidity memory poolLiquidity = 
            ReaderUtils.getPoolLiquidity(dataStore, pool.poolToken);
        return poolLiquidity;

    }


    function getAccountLiquidities(DataStore dataStore, address account) external view returns (ReaderUtils.AccountLiquidity[] memory) {
        Position.Props[] memory positions = _getPositions(dataStore, account);
        ReaderUtils.AccountLiquidity[] memory accountLiquidities = 
            new ReaderUtils.AccountLiquidity[](positions.length);
        for (uint256 i; i < positions.length; i++) {
            address poolKey = Keys.poolKey(positions[i].underlyingAsset);
            Pool.Props memory pool = _getPool(dataStore, poolKey);
            accountLiquidities[i] = 
                ReaderUtils.getAccountLiquidity(dataStore, pool.poolToken, account);
        }
        return accountLiquidities;
    }

    function getAccountLiquidity(DataStore dataStore, address poolKey, address account) external view returns (ReaderUtils.AccountLiquidity memory) {
        Pool.Props memory pool = _getPool(dataStore, poolKey);
        ReaderUtils.AccountLiquidity memory accountLiquidity = 
            ReaderUtils.getAccountLiquidity(dataStore, pool.poolToken, account);
        return accountLiquidity;
    }



    // function getOracle(DataStore dataStore, address underlyingAsset) external view returns (address) {
    //     return OracleStoreUtils.get(dataStore, underlyingAsset);
    // }

    // function getOracleDecimals(DataStore dataStore, address underlyingAsset) external view returns (uint256) {
    //     return OracleStoreUtils.getOracleDecimals(dataStore, underlyingAsset);
    // }

    function getPrice(DataStore dataStore, address underlyingAsset) external view returns (uint256) {
        return OracleUtils.getPrice(dataStore, underlyingAsset);
    }

}
