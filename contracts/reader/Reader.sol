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

    // function _getPool(address dataStore, address poolKey) internal view returns (Pool.Props memory) {
    //     return PoolStoreUtils.get(dataStore, poolKey);
    // }

    // function _getPools(address dataStore, uint256 start, uint256 end) internal view returns (Pool.Props[] memory) {
    //     address[] memory poolKeys = PoolStoreUtils.getPoolKeys(dataStore, start, end);
    //     Pool.Props[] memory pools = new Pool.Props[](poolKeys.length);
    //     for (uint256 i; i < poolKeys.length; i++) {
    //         address poolKey = poolKeys[i];
    //         Pool.Props memory pool = PoolStoreUtils.get(dataStore, poolKey);
    //         pools[i] = pool;
    //     }

    //     return pools;
    // }

   function getPosition(address dataStore, bytes32 positionKey) external view returns (Position.Props memory) {
        return ReaderUtils._getPosition(dataStore, positionKey);
    }

    function getPositions(address dataStore, address account) external view returns (Position.Props[] memory) {
        return ReaderUtils._getPositions(dataStore, account);
    }

    function getPool(address dataStore, address poolKey) external view returns (Pool.Props memory) {
        return ReaderUtils._getPool(dataStore, poolKey);
    }

    function getPools(address dataStore) external view returns (Pool.Props[] memory) {
        uint256 poolsCount = PoolStoreUtils.getPoolCount(dataStore);
        return ReaderUtils._getPools(dataStore, 0, poolsCount);
    }

    function getPoolInfo(address dataStore, address poolKey) external view returns (ReaderUtils.GetPoolInfo memory) {
        return ReaderUtils._getPoolInfo(dataStore, poolKey);
    }

    function getPoolsInfo(address dataStore) external view returns (ReaderUtils.GetPoolInfo[] memory) {
        uint256 poolsCount = PoolStoreUtils.getPoolCount(dataStore);
        return ReaderUtils._getPoolsInfo(dataStore, 0, poolsCount);
    }

    function getPoolsLiquidityAndDebt(address dataStore) external view returns (ReaderUtils.PoolLiquidityAndDebt[] memory) {
        uint256 poolsCount = PoolStoreUtils.getPoolCount(dataStore);
        address[] memory poolKeys = PoolStoreUtils.getPoolKeys(dataStore, 0, poolsCount);
        ReaderUtils.PoolLiquidityAndDebt[] memory poolsLiquidity = 
            new ReaderUtils.PoolLiquidityAndDebt[](poolKeys.length);

        for (uint256 i; i < poolKeys.length; i++) {
            address poolToken = PoolStoreUtils.getPoolToken(dataStore, poolKeys[i]);
            address debtToken = PoolStoreUtils.getDebtToken(dataStore, poolKeys[i]);
            poolsLiquidity[i] = ReaderUtils._getPoolLiquidityAndDebt(dataStore, poolToken, debtToken);
        }
        return poolsLiquidity;
    }

    function getPoolLiquidityAndDebt(address dataStore, address poolKey) external view returns (ReaderUtils.PoolLiquidityAndDebt memory) {
        //Pool.Props memory pool = ReaderUtils._getPool(dataStore, poolKey);
        address poolToken = PoolStoreUtils.getPoolToken(dataStore, poolKey);
        address debtToken = PoolStoreUtils.getDebtToken(dataStore, poolKey);

        ReaderUtils.PoolLiquidityAndDebt memory poolLiquidity = 
            ReaderUtils._getPoolLiquidityAndDebt(dataStore, poolToken, debtToken);
        return poolLiquidity;

    }

    function getAccountLiquidityAndDebtInPools(address dataStore, address account) external view returns (ReaderUtils.AccountLiquidityAndDebt[] memory) {
        uint256 poolsCount = PoolStoreUtils.getPoolCount(dataStore);
        address[] memory poolKeys = PoolStoreUtils.getPoolKeys(dataStore, 0, poolsCount);

        ReaderUtils.AccountLiquidityAndDebt[] memory accountLiquidities = 
            new ReaderUtils.AccountLiquidityAndDebt[](poolKeys.length);
        for (uint256 i; i < poolKeys.length; i++) {
            address poolToken = PoolStoreUtils.getPoolToken(dataStore, poolKeys[i]);
            address debtToken = PoolStoreUtils.getDebtToken(dataStore, poolKeys[i]);
            accountLiquidities[i] = 
                ReaderUtils._getAccountLiquidityAndDebt(account, dataStore, poolToken, debtToken);
        }
        //TODO:should delete empty Liquidities
        return accountLiquidities;
    }

    function getAccountLiquidityAndDebt(address dataStore, address poolKey, address account) external view returns (ReaderUtils.AccountLiquidityAndDebt memory) {
        address poolToken = PoolStoreUtils.getPoolToken(dataStore, poolKey);
        address debtToken = PoolStoreUtils.getDebtToken(dataStore, poolKey);
        ReaderUtils.AccountLiquidityAndDebt memory accountLiquidity = 
            ReaderUtils._getAccountLiquidityAndDebt(account, dataStore, poolToken, debtToken);
        return accountLiquidity;
    }

    // function getOracle(address dataStore, address underlyingAsset) external view returns (address) {
    //     return OracleStoreUtils.get(dataStore, underlyingAsset);
    // }

    // function getOracleDecimals(address dataStore, address underlyingAsset) external view returns (uint256) {
    //     return OracleStoreUtils.getOracleDecimals(dataStore, underlyingAsset);
    // }

    function getPrice(address dataStore, address underlyingAsset) external view returns (uint256) {
        return OracleUtils.getPrice(dataStore, underlyingAsset);
    }

}
