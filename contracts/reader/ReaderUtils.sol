// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../data/DataStore.sol";
import "../data/Keys.sol";

import "../pool/PoolUtils.sol";
import "../pool/PoolStoreUtils.sol";
import "../pool/Pool.sol";
import "../position/PositionStoreUtils.sol";
import "../position/PositionUtils.sol";
import "../token/IPoolToken.sol";
import "../token/IDebtToken.sol";
import "../oracle/OracleUtils.sol";

// @title OracleUtils
library ReaderUtils {

    struct GetLiquidityAndDebt {
        address underlyingAsset;
        address account;
        uint256 balance;
        uint256 scaled;

        uint256 collateral;
        uint256 scaledDebt;
        uint256 debt; 
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
        uint256 totalFee;
        uint256 unclaimedFee;
        uint256 lastUpdateTimestamp;

        bool isActive;
        bool isPaused;
        bool isFrozen;
        bool borrowingEnabled;
        uint256 decimals;
        uint256 borrowCapacity;
        uint256 supplyCapacity;
        uint256 feeFactor;

        uint256 scaledTotalSupply;
        uint256 totalSupply;
        uint256 totalCollateral;
        uint256 availableLiquidity;
        uint256 scaledTotalDebt;
        uint256 totalDebt;

        string symbol;
        uint256 price;
        bool isUsd;
    }

    function _getLiquidityAndDebt(
        address account,
        address dataStore, 
        address poolTokenAddress, 
        address debtTokenAddress
    ) internal view returns (GetLiquidityAndDebt memory) {
        IPoolToken poolToken   = IPoolToken(poolTokenAddress);
        IDebtToken debtToken   = IDebtToken(debtTokenAddress);

        GetLiquidityAndDebt memory l = GetLiquidityAndDebt(
            poolToken.underlyingAsset(),
            account,
            poolToken.balanceOf(account),
            poolToken.scaledBalanceOf(account),
            poolToken.balanceOfCollateral(account),
            debtToken.scaledBalanceOf(account),
            debtToken.balanceOf(account)
        );
        return l;
    }

    function _getPosition(address dataStore, bytes32 positionKey) internal view returns (Position.Props memory) {
        return PositionStoreUtils.get(dataStore, positionKey);
    }

    function _getPositions(address dataStore, address account) internal view returns (Position.Props[] memory) {
        // uint256 positionCount = PositionStoreUtils.getAccountPositionCount(dataStore, account);
        // bytes32[] memory positionKeys = 
        //     PositionStoreUtils.getAccountPositionKeys(dataStore, account, 0, positionCount);
        // Position.Props[] memory positions = 
        //     new Position.Props[](positionKeys.length);
        // for (uint256 i; i < positionKeys.length; i++) {
        //     bytes32 positionKey = positionKeys[i];
        //     Position.Props memory position = PositionStoreUtils.get(dataStore, positionKey);
        //     positions[i] = position;
        // }

        // return positions;
        return PositionUtils.getPositions(account, dataStore);
    }

    function _getPool(address dataStore, address poolKey) internal view returns (Pool.Props memory) {
        return PoolStoreUtils.get(dataStore, poolKey);
    }

    function _getPools(address dataStore, uint256 start, uint256 end) internal view returns (Pool.Props[] memory) {
        address[] memory poolKeys = PoolStoreUtils.getPoolKeys(dataStore, start, end);
        Pool.Props[] memory pools = new Pool.Props[](poolKeys.length);
        for (uint256 i; i < poolKeys.length; i++) {
            address poolKey = poolKeys[i];
            Pool.Props memory pool = PoolStoreUtils.get(dataStore, poolKey);
            pools[i] = pool;
        }

        return pools;
    }

    function _getPoolInfo(address dataStore, address poolKey) internal view returns (GetPoolInfo memory) {
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
            pool.totalFee,
            pool.unclaimedFee,
            pool.lastUpdateTimestamp,
            false,false,false,false,
            0,0,0,0,
            0,0,0,0,0,0,
            "",
            0,
            false    
        );
        (   poolInfo.isActive,
            poolInfo.isFrozen,
            poolInfo.borrowingEnabled,
            poolInfo.isPaused
        ) = PoolConfigurationUtils.getFlags(poolInfo.configuration); 

        poolInfo.isUsd = PoolConfigurationUtils.getUsd(poolInfo.configuration); 

        poolInfo.decimals = PoolConfigurationUtils.getDecimals(poolInfo.configuration);
        poolInfo.borrowCapacity = PoolConfigurationUtils.getBorrowCapacity(poolInfo.configuration);
        poolInfo.supplyCapacity = PoolConfigurationUtils.getSupplyCapacity(poolInfo.configuration);
        poolInfo.feeFactor = PoolConfigurationUtils.getFeeFactor(poolInfo.configuration);
 
        IPoolToken poolToken   = IPoolToken(pool.poolToken);
        IDebtToken debtToken   = IDebtToken(pool.debtToken);
        poolInfo.scaledTotalSupply = poolToken.scaledTotalSupply();
        poolInfo.totalSupply = poolToken.totalSupply();
        poolInfo.totalCollateral = poolToken.totalCollateral();
        poolInfo.availableLiquidity = poolToken.availableLiquidity();
        poolInfo.scaledTotalDebt = debtToken.scaledTotalSupply();
        poolInfo.totalDebt = debtToken.totalSupply();

        poolInfo.symbol = IERC20Metadata(poolInfo.underlyingAsset).symbol();
        //this price is not at lastUpdateTimestamp
        poolInfo.price = OracleUtils.getPrice(dataStore, poolInfo.underlyingAsset);

        return poolInfo;
    }

    function _getPoolsInfo(address dataStore, uint256 start, uint256 end) internal view returns (GetPoolInfo[] memory) {
        address[] memory poolKeys = PoolStoreUtils.getPoolKeys(dataStore, start, end);
        GetPoolInfo[] memory poolsInfo = new GetPoolInfo[](poolKeys.length);
        for (uint256 i; i < poolKeys.length; i++) {
            address poolKey = poolKeys[i];
            poolsInfo[i] = _getPoolInfo(dataStore, poolKey);
        }

        return poolsInfo;
    }

    function _getMaxAmountToRedeem(address dataStore, address underlyingAsset, address account) internal view returns (uint256) {
        address poolKey = Keys.poolKey(underlyingAsset);
        Pool.Props memory pool =  PoolStoreUtils.get(dataStore, poolKey);
        PoolUtils.validateEnabledPool(pool, poolKey);
        IPoolToken poolToken = IPoolToken(pool.poolToken);
        uint256 collateralAmount = poolToken.balanceOfCollateral(account);
        return PositionUtils.maxAmountToRedeem(account, dataStore, underlyingAsset, collateralAmount);     
    }

    function _getLiquidationHealthFactor(address dataStore, address account) external view returns (uint256, uint256, bool, uint256, uint256) {
        return PositionUtils.getLiquidationHealthFactor(account, dataStore);
    }
    
}
