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

// @title ReaderPositionUtils
library ReaderPositionUtils {
    using WadRayMath for uint256;

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

    function abs(int256 value) internal pure returns (uint256){
        return (value > 0) ? uint256(value) : uint256(-value);
    }

    function _getPosition(address dataStore, bytes32 positionKey) internal view returns (Position.Props memory) {
        return PositionStoreUtils.get(dataStore, positionKey);
    }

    function _getPositions(address dataStore, address account) internal view returns (Position.Props[] memory) {
        return PositionUtils.getPositions(account, dataStore);
    }

    function _getPositionInfo(address dataStore, bytes32 positionKey) internal view returns (GetPositionInfo memory) {
        Position.Props memory p = PositionStoreUtils.get(dataStore, positionKey);
        GetPositionInfo memory positionInfo = GetPositionInfo(
            p.account,
            p.underlyingAsset,
            p.positionType,
            0,0,0,0,0,0,0
        );

        positionInfo.indexPrice = OracleUtils.getPrice(dataStore, p.underlyingAsset);
        
        address poolKey = Keys.poolKey(p.underlyingAsset);
        address poolToken = PoolStoreUtils.getPoolToken(dataStore, poolKey);
        address debtToken = PoolStoreUtils.getDebtToken(dataStore, poolKey);
        uint256 configuration = PoolStoreUtils.getConfiguration(dataStore, poolKey);
        uint256 decimals = PoolConfigurationUtils.getDecimals(configuration);

        uint256 collateralAmount = IPoolToken(poolToken).balanceOfCollateral(p.account);
        uint256 debtAmount = IDebtToken(debtToken).balanceOf(p.account);
        
        uint256 equityAbs = ReaderPositionUtils.abs(int256(collateralAmount - debtAmount));
        uint256 adjustEquityAbs = Math.mulDiv(equityAbs, WadRayMath.RAY, 10**decimals);
        uint256 equityValueAbs = adjustEquityAbs.rayMul(positionInfo.indexPrice);
        bool collateralHigherThanDebt = (collateralAmount > debtAmount) ? true : false;

        positionInfo.equity = collateralHigherThanDebt ? int256(equityAbs): -int256(equityAbs);
        positionInfo.equityUsd = collateralHigherThanDebt ? int256(equityValueAbs) : -int256(equityValueAbs);

        if (p.positionType == 0) {
            positionInfo.entryPrice = p.entryShortPrice;          
        } else if (p.positionType == 1) {
            positionInfo.entryPrice = p.entryLongPrice;
        } 

        if (p.positionType != 2) {
            uint256 deltaPriceAbs = ReaderPositionUtils.abs(int256(positionInfo.indexPrice - positionInfo.entryPrice));
            uint256 pnlUsdAbs = adjustEquityAbs.rayMul(deltaPriceAbs);
            bool isPriceIncrease = (positionInfo.indexPrice > positionInfo.entryPrice) ? true : false;

            //short, the collateral should lower than debt
            //long, the collateral should higher than debt
            positionInfo.pnlUsd = (isPriceIncrease&&collateralHigherThanDebt) ? int256(pnlUsdAbs) : -int256(pnlUsdAbs);
            
            (   uint256 userTotalCollateralUsd,
                uint256 userTotalDebtUsd
            ) = PositionUtils.calculateUserTotalCollateralAndDebt(p.account, dataStore, p.underlyingAsset);
            uint256 marginEquityUsd = userTotalCollateralUsd - userTotalDebtUsd;
            positionInfo.liquidationPrice = marginEquityUsd.rayDiv(equityAbs);
            positionInfo.presentageToLiquidationPrice = positionInfo.indexPrice.rayDiv(positionInfo.liquidationPrice);
        }

        return positionInfo;

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

    
}
