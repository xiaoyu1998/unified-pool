// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "../data/DataStore.sol";
import "../error/Errors.sol";

import "../pool/Pool.sol";
import "../pool/PoolStoreUtils.sol";
import "../token/IPoolToken.sol";
import "../token/IDebtToken.sol";

import "./Position.sol";
import "./PositionStoreUtils.sol";

import "../oracle/IPriceFeed.sol";
import "../oracle/OracleUtils.sol";
//import "../config/ConfigStoreUtils.sol";

// @title PositionUtils
// @dev Library for Position functions
library PositionUtils {
    using Position for Position.Props;
    using Pool for Pool.Props;
    using WadRayMath for uint256;
    //using PoolConfigurationUtils for uint256;

    function getOrInit(
        address account,
        address dataStore, 
        address underlyingAsset,
        uint256 positionType,
        bool poolIsUsd
    ) internal view returns (Position.Props memory, bytes32) {
        bytes32 positionKey = Keys.accountPositionKey(underlyingAsset, account);
        Position.Props memory position = PositionStoreUtils.get(dataStore, positionKey);
        if(position.account == address(0)){
            position.account = account;
            position.underlyingAsset = underlyingAsset;
            PositionUtils.reset(position);
            if (!poolIsUsd) {
                position.positionType = positionType;
            }
        }

        return (position, positionKey);
    }

    function validateEnabledPosition(Position.Props memory postion) internal pure {
        if (postion.account == address(0)) {
            revert Errors.EmptyPosition();
        }

    }

    function reset(Position.Props memory postion) internal pure {
        postion.entryLongPrice = 0;
        postion.accLongAmount = 0;
        postion.entryShortPrice = 0;
        postion.accShortAmount = 0;
        postion.positionType = Position.PositionTypeNone;
        postion.hasCollateral = false;
        postion.hasDebt = false;
    }

    function calculateUserTotalCollateralAndDebt(
        address account,
        address dataStore,
        address exceptUnderlyingAsset
    ) internal view returns (uint256, uint256) {
        Position.Props[] memory positions = PositionStoreUtils.getPositions(dataStore, account);
        uint256 userTotalCollateralUsd;
        uint256 userTotalDebtUsd;        
        for (uint256 i = 0; i < positions.length; i++) {
            Position.Props memory position = positions[i];
            if (position.underlyingAsset == exceptUnderlyingAsset) {
                continue;
            }

            (   uint256 userCollateralUsd, 
                uint256 userDebtUsd) = 
                calculateUserCollateralAndDebtInPosition(dataStore, position);

            userTotalCollateralUsd += userCollateralUsd;
            userTotalDebtUsd += userDebtUsd;            
        }

        return (userTotalCollateralUsd, userTotalDebtUsd);

    }

    function calculateUserCollateralAndDebtInPosition(
        address dataStore,
        Position.Props memory position
    ) internal view returns (uint256, uint256) {
        uint256 assetPrice = OracleUtils.getPrice(dataStore, position.underlyingAsset);
        
        uint256 userCollateralUsd;
        uint256 userDebtUsd;

        uint256 configuration = PoolStoreUtils.getConfiguration(dataStore, position.underlyingAsset);
        uint256 decimals = PoolConfigurationUtils.getDecimals(configuration);

        if (position.hasCollateral){
            address poolToken = PoolStoreUtils.getPoolToken(dataStore, position.underlyingAsset);
            uint256 collateral = IPoolToken(poolToken).balanceOfCollateral(position.account);
            uint256 adjustCollateral = Math.mulDiv(collateral, WadRayMath.RAY, 10**decimals);//align to Ray
            userCollateralUsd = adjustCollateral.rayMul(assetPrice);
        }

        if (position.hasDebt){
            address debtToken = PoolStoreUtils.getDebtToken(dataStore, position.underlyingAsset);
            uint256 debt = IDebtToken(debtToken).balanceOf(position.account);
            uint256 adjustDebt = Math.mulDiv(debt, WadRayMath.RAY, 10**decimals);//align to Ray
            userDebtUsd = adjustDebt.rayMul(assetPrice);
        }

        return (userCollateralUsd, userDebtUsd);
    }
    // T = (C + C1*P)/(D + D1*P)
    // P = (T*D - C)/(C1 - T*D1)
    function getLiquidationPrice(
        address dataStore,
        uint256 userTotalOtherCollateralslUsd,
        uint256 userTotalOtherDebtsUsd,
        uint256 collateralAmount,
        uint256 debtAmount
    ) internal view returns(uint256) {
         uint256 threshold =
            PositionStoreUtils.getHealthFactorLiquidationThreshold(dataStore);

        uint256 thresholdMulDebt = threshold.rayMul(userTotalOtherDebtsUsd);
        int256 thresholdMulDebtSubCollateral = int256(thresholdMulDebt) - int256(userTotalOtherCollateralslUsd);
        uint256 threasholdMulDebt1 = threshold.rayMul(debtAmount);
        int256  Collatera1SubThreasholdMulDebt1 = int256(collateralAmount) - int256(threasholdMulDebt1);

        uint256 thresholdMulDebtSubCollateralAbs = SignedMath.abs(thresholdMulDebtSubCollateral);
        uint256 Collatera1SubThreasholdMulDebt1Abs = SignedMath.abs(Collatera1SubThreasholdMulDebt1);

        //negative price 
        if (( thresholdMulDebtSubCollateral > 0 && Collatera1SubThreasholdMulDebt1 < 0) ||
           ( thresholdMulDebtSubCollateral < 0 && Collatera1SubThreasholdMulDebt1 > 0)) {
            return 0;
        }

        return (Collatera1SubThreasholdMulDebt1Abs == 0)?0:thresholdMulDebtSubCollateralAbs.rayDiv(Collatera1SubThreasholdMulDebt1Abs);
    }

    function getLiquidationHealthFactor(
        address account,
        address dataStore
    ) internal view returns(uint256, uint256, bool, uint256, uint256) {
        (   uint256 userTotalCollateralUsd,
            uint256 userTotalDebtUsd
        ) = PositionUtils.calculateUserTotalCollateralAndDebt(account, dataStore, address(0));

        //uint256 healthFactor;
        // if (userTotalDebtUsd > 0 )
        //     healthFactor = userTotalCollateralUsd.rayDiv(userTotalDebtUsd);
        // else
        //     healthFactor = type(uint256).max;

        uint256 healthFactor = (userTotalDebtUsd > 0 ) 
            ? userTotalCollateralUsd.rayDiv(userTotalDebtUsd)
            : type(uint256).max;

        uint256 healthFactorLiquidationThreshold =
            PositionStoreUtils.getHealthFactorLiquidationThreshold(dataStore);

        return (healthFactor,  
                healthFactorLiquidationThreshold, 
                (userTotalDebtUsd == 0) ? true : (healthFactor > healthFactorLiquidationThreshold),
                userTotalCollateralUsd,
                userTotalDebtUsd);
    }

    function validateLiquidationHealthFactor(
        address account,
        address dataStore,
        address underlyingAsset,
        uint256 amount,
        uint256 decimals
    ) internal view {
        (   uint256 userTotalCollateralUsd,
            uint256 userTotalDebtUsd
        ) = PositionUtils.calculateUserTotalCollateralAndDebt(account, dataStore, address(0));

        if (userTotalCollateralUsd == 0) { 
            revert Errors.EmptyCollateral();
        }
        
        uint256 adjustAmount = Math.mulDiv(amount, WadRayMath.RAY, 10**decimals);//align to Ray
        uint256 amountUsd = OracleUtils.getPrice(dataStore, underlyingAsset)
                                            .rayMul(adjustAmount);

        uint256 healthFactor = 
            (userTotalCollateralUsd + amountUsd).rayDiv(userTotalDebtUsd + amountUsd);

        uint256 healthFactorLiquidationThreshold =
            PositionStoreUtils.getHealthFactorLiquidationThreshold(dataStore);

        if (healthFactor < healthFactorLiquidationThreshold) {
            revert Errors.HealthFactorLowerThanLiquidationThreshold(
                healthFactor, 
                healthFactorLiquidationThreshold
            );
        }
    }

    function validateCollateralRateHealthFactor(
        address dataStore,
        address underlyingAsset,
        uint256 collateralAmount,
        uint256 debtAmount,
        uint256 amount
    ) internal view {
        uint256 healthFactor = 
            (collateralAmount + amount).rayDiv(debtAmount + amount);
        uint256 healthFactorCollateralRateThreshold =
            PositionStoreUtils.getHealthFactorCollateralRateThreshold(dataStore, underlyingAsset); 

        if (healthFactor < healthFactorCollateralRateThreshold) {
            revert Errors.HealthFactorLowerThanCollateralRateThreshold(
                healthFactor, 
                healthFactorCollateralRateThreshold
            );
        }
    }

    struct MaxAmountToRedeemLocalVars {
        uint256 userTotalCollateralUsd;
        uint256 userTotalDebtUsd;
        uint256 multiplierFactor;
        uint256 timesTotalDebtUsd;
        uint256 price;
        uint256 totalAvailable;
        uint256 configuration;
        uint256 decimals;
        uint256 adjustTotalAvailable;
    }

    function maxAmountToRedeem(
        address account,
        address dataStore,
        address underlyingAsset,
        uint256 collateralAmount
    ) internal view returns (uint256) {
        MaxAmountToRedeemLocalVars memory vars;

        if (collateralAmount == 0) {
            return 0;
        }

        (   vars.userTotalCollateralUsd,
            vars.userTotalDebtUsd
        ) = PositionUtils.calculateUserTotalCollateralAndDebt(account, dataStore, address(0));

        if (vars.userTotalCollateralUsd == 0) { 
            return 0;
        }

        vars.multiplierFactor = PositionStoreUtils.getDebtMultiplierFactorForRedeem(dataStore);
        vars.timesTotalDebtUsd = vars.userTotalDebtUsd.rayMul(vars.multiplierFactor);
        if (vars.userTotalCollateralUsd < vars.timesTotalDebtUsd) {
            return 0;
        }
        vars.price = OracleUtils.getPrice(dataStore, underlyingAsset);
        vars.totalAvailable = (vars.userTotalCollateralUsd - vars.timesTotalDebtUsd).rayDiv(vars.price);

        vars.configuration = PoolStoreUtils.getConfiguration(dataStore, underlyingAsset);
        vars.decimals = PoolConfigurationUtils.getDecimals(vars.configuration);  
        vars.adjustTotalAvailable = Math.mulDiv(vars.totalAvailable, 10**vars.decimals, WadRayMath.RAY);      

        if (vars.adjustTotalAvailable > collateralAmount) {
            return collateralAmount;
        }

        return vars.adjustTotalAvailable;
    }

    function longPosition(
      Position.Props memory position,
      uint256 price,
      uint256 amount,
      bool isNewPriceAccToEntryPrice
    ) internal pure {
        //1st deposit/repay/swap after reset
        if (position.positionType == Position.PositionTypeNone) {
            position.positionType = Position.PositionTypeLong;
            position.accLongAmount = amount;
            position.entryLongPrice = price;
        }else if (position.positionType == Position.PositionTypeLong) {
            uint256 preAccLongAmount = position.accLongAmount;
            position.accLongAmount += amount;
            if (isNewPriceAccToEntryPrice){
                uint256 totalValue = position.entryLongPrice.rayMul(preAccLongAmount) +
                                     price.rayMul(amount);
                position.entryLongPrice = totalValue.rayDiv(position.accLongAmount);
            }
        }else if(position.positionType == Position.PositionTypeShort) {
            if (position.accShortAmount > amount){
                position.accShortAmount -= amount;
            } else {
                position.positionType = Position.PositionTypeLong;
                position.accLongAmount = amount - position.accShortAmount;
                position.accShortAmount = 0;
                position.entryShortPrice = 0;
                position.entryLongPrice = price;
            }
        }
    }

    function shortPosition(
      Position.Props memory position,
      uint256 price,
      uint256 amount,
      bool isNewPriceAccToEntryPrice
    ) internal pure {
        //1st redeem/swap after reset
        if (position.positionType == Position.PositionTypeNone) {
            position.positionType = Position.PositionTypeShort;
            position.accShortAmount = amount;
            position.entryShortPrice = price;
        }else if (position.positionType == Position.PositionTypeShort) {
            uint256 preAccShortAmount = position.accShortAmount;
            position.accShortAmount += amount;
            if (isNewPriceAccToEntryPrice){//
                uint256 totalValue = position.entryShortPrice.rayMul(preAccShortAmount) +
                                     price.rayMul(amount);
                position.entryShortPrice = totalValue.rayDiv(position.accShortAmount);
            }
        }else if (position.positionType == Position.PositionTypeLong) {
            if (position.accLongAmount > amount){
                position.accLongAmount -= amount;
            } else {
                position.positionType = Position.PositionTypeShort;
                position.accShortAmount = amount - position.accLongAmount;
                position.accLongAmount = 0;
                position.entryLongPrice = 0;
                position.entryShortPrice = price;
            }
        }
    }


}