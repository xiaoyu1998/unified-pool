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
//import "../position/PositionStoreUtils.sol";
import "../position/PositionUtils.sol";
import "../token/IPoolToken.sol";
import "../token/IDebtToken.sol";
import "../oracle/OracleUtils.sol";

// @title ReaderUtils
library ReaderUtils {
    using WadRayMath for uint256;

    struct GetLiquidityAndDebt {
        address underlyingAsset;
        address account;
        uint256 balance;
        uint256 scaled;

        uint256 collateral;
        uint256 scaledDebt;
        uint256 debt; 
    }

    function _getLiquidityAndDebt(
        address account,
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

    struct GetMarginAndSupply {
        address underlyingAsset;
        address account;
        uint256 balanceAsset;
        uint256 debt; 
        uint256 borrowApy;
        uint256 maxWithdrawAmount;
        uint256 balanceSupply;
        uint256 supplyApy;
    }

    struct GetMarginAndSupplyLocalVars {
        address poolTokenAddress;
        address debtTokenAddress;
        IPoolToken poolToken;
        IDebtToken debtToken;
        address underlyingAsset;
        uint256 collateralAmount;
        uint256 maxWithdrawAmount;
        uint256 borrowApy;
        uint256 supplyApy;
    } 

    function _getMarginAndSupply (
        address dataStore,
        address account,
        address poolKey
    ) internal view returns (GetMarginAndSupply memory) {
        GetMarginAndSupplyLocalVars memory vars;
        vars.poolTokenAddress = PoolStoreUtils.getPoolToken(dataStore, poolKey);
        vars.debtTokenAddress = PoolStoreUtils.getDebtToken(dataStore, poolKey);
        vars.supplyApy = PoolStoreUtils.getLiquidatyRate(dataStore, poolKey);
        vars.borrowApy = PoolStoreUtils.getBorrowRate(dataStore, poolKey);
        vars.poolToken   = IPoolToken(vars.poolTokenAddress);
        vars.debtToken   = IDebtToken(vars.debtTokenAddress);

        vars.underlyingAsset = vars.poolToken.underlyingAsset();
        vars.collateralAmount = vars.poolToken.balanceOfCollateral(account);
        vars.maxWithdrawAmount = PositionUtils.maxAmountToRedeem(
            account, 
            dataStore, 
            vars.underlyingAsset, 
            vars.collateralAmount
        );

        GetMarginAndSupply memory m = GetMarginAndSupply(
            vars.underlyingAsset,
            account,
            vars.collateralAmount,
            vars.debtToken.balanceOf(account),
            vars.borrowApy,
            vars.maxWithdrawAmount,
            vars.poolToken.balanceOf(account),
            vars.supplyApy
        );

        return m;
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

        uint256 borrowUsageRatio;
        uint256 optimalUsageRatio;
        uint256 rateBase;
        uint256 rateSlope1;
        uint256 rateSlope2;

        string symbol;
        uint256 price;
        bool isUsd;
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
            0,0,0,0,0,
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
 
         uint256 unclaimedFee = pool.unclaimedFee.rayMul(
            pool.borrowIndex
        );

        IPoolToken poolToken   = IPoolToken(pool.poolToken);
        IDebtToken debtToken   = IDebtToken(pool.debtToken);
        poolInfo.scaledTotalSupply = poolToken.scaledTotalSupply();
        poolInfo.totalSupply = poolToken.totalSupply();
        poolInfo.totalCollateral = poolToken.totalCollateral();
        poolInfo.availableLiquidity = poolToken.availableLiquidity(unclaimedFee);
        poolInfo.scaledTotalDebt = debtToken.scaledTotalSupply();
        poolInfo.totalDebt = debtToken.totalSupply();
        
        poolInfo.borrowUsageRatio = (poolInfo.totalDebt == 0)? 0:poolInfo.totalDebt.rayDiv(poolInfo.availableLiquidity + poolInfo.totalDebt);

        IPoolInterestRateStrategy strategy = IPoolInterestRateStrategy(poolInfo.interestRateStrategy);
        poolInfo.rateBase = strategy.getRatebase();
        poolInfo.optimalUsageRatio = strategy.getOptimalUsageRatio();
        poolInfo.rateSlope1 = strategy.getRateSlope1();
        poolInfo.rateSlope2 = strategy.getRateSlope2();

        poolInfo.symbol = IERC20Metadata(poolInfo.underlyingAsset).symbol();
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

    struct GetPoolPrice {
        address underlyingAsset;
        string symbol;
        uint256 price;
        uint256 decimals;
    }

    function _getPoolPrice(address dataStore, address poolKey) internal view returns (GetPoolPrice memory) {
        Pool.Props memory pool =  PoolStoreUtils.get(dataStore, poolKey);
        GetPoolPrice memory poolPrice = GetPoolPrice(
            pool.underlyingAsset,
            IERC20Metadata(pool.underlyingAsset).symbol(),
            OracleUtils.getPrice(dataStore, pool.underlyingAsset),
            PoolConfigurationUtils.getDecimals(pool.configuration)
        );

        return poolPrice;
    }

    function _getPoolsPrice(address dataStore, uint256 start, uint256 end) internal view returns (GetPoolPrice[] memory) {
        address[] memory poolKeys = PoolStoreUtils.getPoolKeys(dataStore, start, end);
        GetPoolPrice[] memory poolsPrice = new GetPoolPrice[](poolKeys.length);
        for (uint256 i; i < poolKeys.length; i++) {
            address poolKey = poolKeys[i];
            poolsPrice[i] = _getPoolPrice(dataStore, poolKey);
        }

        return poolsPrice;
    }
    
}
