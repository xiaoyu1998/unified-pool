// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
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

// @title ReaderPositionUtils
library ReaderPositionUtils {
    using WadRayMath for uint256;

    function _getPosition(address dataStore, bytes32 positionKey) internal view returns (Position.Props memory) {
        //bytes32 positionKey = Keys.accountPositionKey(poolKey, account);
        return PositionStoreUtils.get(dataStore, positionKey);
    }

    // function _getPosition(address dataStore, bytes32 positionKey) internal view returns (Position.Props memory) {
    //     return PositionStoreUtils.get(dataStore, positionKey);
    // }

    // function _getPositions(address dataStore, address account, uint256 start, uint256 end) internal view returns (Position.Props[] memory) {
    //     // return PositionUtils.getPositions(account, dataStore);
    //     bytes32[] memory positionKeys = 
    //         PositionStoreUtils.getAccountPositionKeys(dataStore, account, start, end);
    //     Position.Props[] memory positions = new Position.Props[](positionKeys.length);
    //     for (uint256 i; i < positionKeys.length; i++) {
    //         bytes32 positionKey = positionKeys[i];
    //         positions[i] = _getPosition(dataStore, positionKey);
    //     }

    //     return positions;

    // }

    function _getPositions(address dataStore, address account) internal view returns (Position.Props[] memory) {
        return PositionStoreUtils.getPositions(dataStore, account);
    }
    
    struct GetPositionInfo {
        address account;
        address underlyingAsset;
        uint256 positionType;
        int256 equity;
        int256 equityUsd;
        uint256 indexPrice;
        uint256 entryPrice;
        int256 pnlUsd; 
        uint256 liquidationPrice;
        uint256 presentageToLiquidationPrice;
    }

    struct GetPositionInfoLocalVars {
        GetPositionInfo positionInfo;
        Position.Props pool;
        address poolKey;
        address poolToken;
        address debtToken;
        uint256 configuration;
        uint256 decimals;
        uint256 collateralAmount;
        uint256 debtAmount;
        uint256 adjustCollateralAmount;
        uint256 adjustDebtAmount;
        uint256 equityAbs;
        uint256 adjustEquityAbs;
        uint256 equityUsdAbs;
        bool collateralHigherThanDebt;
        uint256 deltaPriceAbs;
        uint256 pnlUsdAbs;
        bool isPriceIncrease;
        uint256 userTotalCollateralExceptThisPositionUsd;
        uint256 userTotalDebExceptThisPositiontUsd;
        uint256 liquidationPrice;
    }   

    function _getPositionInfo(address dataStore, bytes32 positionKey) internal view returns (GetPositionInfo memory) {
        GetPositionInfoLocalVars memory vars;
        vars.pool = PositionStoreUtils.get(dataStore, positionKey);
        vars.positionInfo = GetPositionInfo(
            vars.pool.account,
            vars.pool.underlyingAsset,
            vars.pool.positionType,
            0,0,0,0,0,0,0
        );

        vars.positionInfo.indexPrice = OracleUtils.getPrice(dataStore, vars.pool.underlyingAsset);
        Printer.log("indexPrice", vars.positionInfo.indexPrice);
        
        vars.poolKey = Keys.poolKey(vars.pool.underlyingAsset);
        vars.poolToken = PoolStoreUtils.getPoolToken(dataStore, vars.poolKey);
        vars.debtToken = PoolStoreUtils.getDebtToken(dataStore, vars.poolKey);
        vars.configuration = PoolStoreUtils.getConfiguration(dataStore, vars.poolKey);
        vars.decimals = PoolConfigurationUtils.getDecimals(vars.configuration);

        vars.collateralAmount = IPoolToken(vars.poolToken).balanceOfCollateral(vars.pool.account);
        vars.debtAmount = IDebtToken(vars.debtToken).balanceOf(vars.pool.account);
        vars.adjustCollateralAmount = Math.mulDiv(vars.collateralAmount, WadRayMath.RAY, 10**vars.decimals);
        vars.adjustDebtAmount = Math.mulDiv(vars.debtAmount, WadRayMath.RAY, 10**vars.decimals);
        
        Printer.log("collateralAmount", vars.collateralAmount);
        Printer.log("debtAmount", vars.debtAmount);
        vars.equityAbs = SignedMath.abs(int256(vars.collateralAmount) - int256(vars.debtAmount));
        Printer.log("equityAbs", vars.equityAbs);

        vars.adjustEquityAbs = SignedMath.abs(int256(vars.adjustCollateralAmount) - int256(vars.adjustDebtAmount));
        vars.equityUsdAbs = vars.adjustEquityAbs.rayMul(vars.positionInfo.indexPrice);

        vars.collateralHigherThanDebt = (vars.collateralAmount > vars.debtAmount) ? true : false;
        vars.positionInfo.equity = vars.collateralHigherThanDebt ? int256(vars.equityAbs): -int256(vars.equityAbs);
        vars.positionInfo.equityUsd = vars.collateralHigherThanDebt ? int256(vars.equityUsdAbs) : -int256(vars.equityUsdAbs);
        Printer.log("equitequityUsdyAbs", vars.positionInfo.equityUsd);

        if (vars.pool.positionType == 0) {//short
            vars.positionInfo.entryPrice = vars.pool.entryShortPrice;          
        } else if (vars.pool.positionType == 1) {//long
            vars.positionInfo.entryPrice = vars.pool.entryLongPrice;
        } 

        if (vars.pool.positionType != 2) {
            vars.deltaPriceAbs = SignedMath.abs(int256(vars.positionInfo.indexPrice) - int256(vars.positionInfo.entryPrice));
            vars.pnlUsdAbs = vars.adjustEquityAbs.rayMul(vars.deltaPriceAbs);
            vars.isPriceIncrease = (vars.positionInfo.indexPrice > vars.positionInfo.entryPrice) ? true : false;

            //short, the collateral should lower than debt
            //long, the collateral should higher than debt
            //the collateralHigherThanDebt is same as the isLong
            vars.positionInfo.pnlUsd = (vars.isPriceIncrease&&vars.collateralHigherThanDebt) ? int256(vars.pnlUsdAbs) : -int256(vars.pnlUsdAbs);
            Printer.log("pnlUsd", vars.positionInfo.pnlUsd);
            
            (   vars.userTotalCollateralExceptThisPositionUsd,
                vars.userTotalDebExceptThisPositiontUsd
            ) = PositionUtils.calculateUserTotalCollateralAndDebt(vars.pool.account, dataStore, vars.pool.underlyingAsset);

            Printer.log("userTotalCollateralExceptThisPositionUsd", vars.userTotalCollateralExceptThisPositionUsd);
            Printer.log("userTotalDebExceptThisPositiontUsd", vars.userTotalDebExceptThisPositiontUsd);

            vars.liquidationPrice = PositionUtils.getLiquidationPrice(
                dataStore,
                vars.userTotalCollateralExceptThisPositionUsd,
                vars.userTotalDebExceptThisPositiontUsd,
                vars.adjustCollateralAmount,
                vars.adjustDebtAmount
            );

            vars.positionInfo.liquidationPrice = vars.liquidationPrice;
            vars.positionInfo.presentageToLiquidationPrice = (vars.liquidationPrice == 0)?0:vars.positionInfo.indexPrice.rayDiv(vars.liquidationPrice);

        }

        return vars.positionInfo;

    }

    function _getPositionsInfo(address dataStore, address account, uint256 start, uint256 end) internal view returns (GetPositionInfo[] memory) {
        bytes32[] memory positionKeys = 
            PositionStoreUtils.getAccountPositionKeys(dataStore, account, start, end);
        GetPositionInfo[] memory positionsInfo = new GetPositionInfo[](positionKeys.length);
        for (uint256 i; i < positionKeys.length; i++) {
            bytes32 positionKey = positionKeys[i];
            positionsInfo[i] = _getPositionInfo(dataStore, positionKey);
        }

        return positionsInfo;
    }

    function _getMaxAmountToRedeem(address dataStore, address underlyingAsset, address account) internal view returns (uint256) {
        address poolKey = Keys.poolKey(underlyingAsset);
        Pool.Props memory pool =  PoolStoreUtils.get(dataStore, poolKey);
        PoolUtils.validateEnabledPool(pool, poolKey);
        IPoolToken poolToken = IPoolToken(pool.poolToken);
        uint256 collateralAmount = poolToken.balanceOfCollateral(account);
        return PositionUtils.maxAmountToRedeem(account, dataStore, underlyingAsset, collateralAmount);     
    }

    struct GetLiquidationHealthFactor {
        uint256 healthFactor;
        uint256 healthFactorLiquidationThreshold;
        bool isHealthFactorHigherThanLiquidationThreshold;
        uint256 userTotalCollateralUsd;
        uint256 userTotalDebtUsd;
    }

    function _getLiquidationHealthFactor(address dataStore, address account) external view returns (GetLiquidationHealthFactor memory) {
        GetLiquidationHealthFactor memory liquidationHealthFactor;
        (   liquidationHealthFactor.healthFactor,
            liquidationHealthFactor.healthFactorLiquidationThreshold,
            liquidationHealthFactor.isHealthFactorHigherThanLiquidationThreshold,
            liquidationHealthFactor.userTotalCollateralUsd,
            liquidationHealthFactor.userTotalDebtUsd
        ) = PositionUtils.getLiquidationHealthFactor(account, dataStore);    
        return liquidationHealthFactor;
    }

    
}
