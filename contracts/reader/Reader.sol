// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/Keys.sol";

import "../position/Position.sol";

//import "../oracle/OracleStoreUtils.sol";
//import "../oracle/OracleUtils.sol";

import "./ReaderUtils.sol";


// @title Reader
// @dev Library for read functions
contract Reader {
    using SafeCast for uint256;
    using Position for Position.Props;

    // function _getPool(DataStore dataStore, address poolKey) internal view returns (Pool.Props memory) {
    //     return PoolStoreUtils.get(dataStore, poolKey);
    // }

    // function _getPools(DataStore dataStore, uint256 start, uint256 end) internal view returns (Pool.Props[] memory) {
    //     address[] memory poolKeys = PoolStoreUtils.getPoolKeys(dataStore, start, end);
    //     Pool.Props[] memory pools = new Pool.Props[](poolKeys.length);
    //     for (uint256 i; i < poolKeys.length; i++) {
    //         address poolKey = poolKeys[i];
    //         Pool.Props memory pool = PoolStoreUtils.get(dataStore, poolKey);
    //         pools[i] = pool;
    //     }

    //     return pools;
    // }

   function getPosition(DataStore dataStore, bytes32 positionKey) external view returns (Position.Props memory) {
        return ReaderUtils._getPosition(dataStore, positionKey);
    }

    function getPositions(DataStore dataStore, address account) external view returns (Position.Props[] memory) {
        return ReaderUtils._getPositions(dataStore, account);
    }

    function getPool(DataStore dataStore, address poolKey) external view returns (Pool.Props memory) {
        return ReaderUtils._getPool(dataStore, poolKey);
    }

    function getPools(DataStore dataStore) external view returns (Pool.Props[] memory) {
        uint256 poolsCount = PoolStoreUtils.getPoolCount(dataStore);
        return ReaderUtils._getPools(dataStore, 0, poolsCount);
    }

    function getPoolInfo(DataStore dataStore, address poolKey) external view returns (ReaderUtils.GetPoolInfo memory) {
        return ReaderUtils._getPoolInfo(dataStore, poolKey);
    }

    function getPoolsInfo(DataStore dataStore) external view returns (ReaderUtils.GetPoolInfo[] memory) {
        uint256 poolsCount = PoolStoreUtils.getPoolCount(dataStore);
        return ReaderUtils._getPoolsInfo(dataStore, 0, poolsCount);
    }

    function getPoolsLiquidity(DataStore dataStore) external view returns (ReaderUtils.PoolLiquidity[] memory) {
        uint256 poolsCount = PoolStoreUtils.getPoolCount(dataStore);
        address[] memory poolKeys = PoolStoreUtils.getPoolKeys(dataStore, 0, poolsCount);
        ReaderUtils.PoolLiquidity[] memory poolsLiquidity = 
            new ReaderUtils.PoolLiquidity[](poolKeys.length);

        for (uint256 i; i < poolKeys.length; i++) {
            address poolToken = PoolStoreUtils.getPoolToken(dataStore, poolKeys[i]);
            poolsLiquidity[i] = ReaderUtils._getPoolLiquidity(dataStore, poolToken);
        }
        return poolsLiquidity;
    }

    function getPoolLiquidity(DataStore dataStore, address poolKey) external view returns (ReaderUtils.PoolLiquidity memory) {
        Pool.Props memory pool = ReaderUtils._getPool(dataStore, poolKey);
        ReaderUtils.PoolLiquidity memory poolLiquidity = 
            ReaderUtils._getPoolLiquidity(dataStore, pool.poolToken);
        return poolLiquidity;

    }

    function getAccountLiquidities(DataStore dataStore, address account) external view returns (ReaderUtils.AccountLiquidity[] memory) {
        uint256 poolsCount = PoolStoreUtils.getPoolCount(dataStore);
        address[] memory poolKeys = PoolStoreUtils.getPoolKeys(dataStore, 0, poolsCount);

        ReaderUtils.AccountLiquidity[] memory accountLiquidities = 
            new ReaderUtils.AccountLiquidity[](poolKeys.length);
        for (uint256 i; i < poolKeys.length; i++) {
            address poolToken = PoolStoreUtils.getPoolToken(dataStore, poolKeys[i]);
            accountLiquidities[i] = 
                ReaderUtils._getAccountLiquidity(dataStore, poolToken, account);
        }
        //TODO:should delete empty Liquidities
        return accountLiquidities;
    }

    function getAccountLiquidity(DataStore dataStore, address poolKey, address account) external view returns (ReaderUtils.AccountLiquidity memory) {
        Pool.Props memory pool = ReaderUtils._getPool(dataStore, poolKey);
        ReaderUtils.AccountLiquidity memory accountLiquidity = 
            ReaderUtils._getAccountLiquidity(dataStore, pool.poolToken, account);
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
