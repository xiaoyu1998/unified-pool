// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../data/DataStore.sol";
import "../data/Keys.sol";

import "../pool/PoolStoreUtils.sol";
import "../pool/Pool.sol";
import "../position/PositionStoreUtils.sol";
import "../token/IPoolToken.sol";
import "../oracle/OracleUtils.sol";

// @title OracleUtils
library ReaderUtils {

    struct PoolLiquidity {
        address underlyingAsset;
        uint256 scaledTotalSupply;
        uint256 totalSupply;
        uint256 totalCollateral;
        uint256 availableLiquidity;
    }

    struct AccountLiquidity {
        address underlyingAsset;
        address account;
        uint256 balance;
        uint256 scaled;
        uint256 collateral;
    }

    struct GetPoolInfo {
        uint256 keyId;
        uint256 liquidityIndex;
        uint256 liquidityRate;
        uint256 borrowIndex;
        uint256 borrowRate;
        
        address interestRateStrategy;
        address underlyingAsset;
        address poolToken;
        address debtToken;

        uint256 configuration;
        uint256 feeFactor;
        uint256 totalFee;
        uint256 unclaimedFee;
        uint256 lastUpdateTimestamp;

        bool isActive;
        bool isPaused;
        bool isFrozen;
        bool borrowingEnabled;
        uint256 decimals;

        string symbol;
        uint256 price;
    }

    function getPoolLiquidity(DataStore dataStore, address poolTokenAddress) public view returns (PoolLiquidity memory) {
        IPoolToken poolToken   = IPoolToken(poolTokenAddress);

        PoolLiquidity memory poolLiquidity = PoolLiquidity(
            poolToken.underlyingAsset(),
            poolToken.scaledTotalSupply(),
            poolToken.totalSupply(),
            poolToken.totalCollateral(),
            poolToken.availableLiquidity()
        );
        return poolLiquidity;
    }

    function getAccountLiquidity(
        DataStore dataStore, 
        address poolTokenAddress, 
        address account
    ) public view returns (AccountLiquidity memory) {
        IPoolToken poolToken   = IPoolToken(poolTokenAddress);

        AccountLiquidity memory accountLiquidity = AccountLiquidity(
            poolToken.underlyingAsset(),
            account,
            poolToken.balanceOf(account),
            poolToken.scaledBalanceOf(account),
            poolToken.balanceOfCollateral(account)
        );
        return accountLiquidity;
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

    function _getPoolInfo(DataStore dataStore, address poolKey) internal view returns (GetPoolInfo memory) {
        Pool.Props memory pool =  PoolStoreUtils.get(dataStore, poolKey);
        GetPoolInfo memory poolInfo = GetPoolInfo(
            pool.keyId,
            pool.liquidityIndex,
            pool.liquidityRate,
            pool.borrowIndex,
            pool.borrowRate,
            pool.interestRateStrategy,
            pool.underlyingAsset,
            pool.poolToken,
            pool.debtToken,
            pool.configuration,
            pool.feeFactor,
            pool.totalFee,
            pool.unclaimedFee,
            pool.lastUpdateTimestamp,
            false,
            false,
            false,
            false,
            0,
            "",
            0        
        );
        (   poolInfo.isActive,
            poolInfo.isFrozen,
            poolInfo.borrowingEnabled,
            poolInfo.isPaused
        ) = PoolConfigurationUtils.getFlags(poolInfo.configuration); 

        poolInfo.decimals = PoolConfigurationUtils.getDecimals(poolInfo.configuration);
        poolInfo.symbol = IERC20Metadata(poolInfo.underlyingAsset).symbol();

        //this price is not at lastUpdateTimestamp
        poolInfo.price = OracleUtils.getPrice(dataStore, poolInfo.underlyingAsset);

        return poolInfo;
    }

    function _getPoolsInfo(DataStore dataStore, uint256 start, uint256 end) internal view returns (GetPoolInfo[] memory) {
        address[] memory poolKeys = PoolStoreUtils.getPoolKeys(dataStore, start, end);
        GetPoolInfo[] memory poolsInfo = new GetPoolInfo[](poolKeys.length);
        for (uint256 i; i < poolKeys.length; i++) {
            address poolKey = poolKeys[i];
            poolsInfo[i] = _getPoolInfo(dataStore, poolKey);
        }

        return poolsInfo;
    }
    
}
