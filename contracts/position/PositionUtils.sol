// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

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
import "../config/ConfigStoreUtils.sol";

// @title PositionUtils
// @dev Library for Position functions
library PositionUtils {
    using Position for Position.Props;
    using Pool for Pool.Props;
    using WadRayMath for uint256;
    //using PoolConfigurationUtils for uint256;

    function calculateUserTotalCollateralAndDebt(
        address account,
        address dataStore
    ) internal view returns (uint256, uint256) {
        uint256 positionCount = PositionStoreUtils.getAccountPositionCount(dataStore, account);
        if(positionCount == 0) return (0, 0);

        bytes32[] memory positionKeys = 
            PositionStoreUtils.getAccountPositionKeys(dataStore, account, 0, positionCount);
        uint256 userTotalCollateralUsd;
        uint256 userTotalDebtUsd;        
        for (uint256 i = 0; i < positionKeys.length; i++) {
            Position.Props memory position = PositionStoreUtils.get(dataStore, positionKeys[i]);
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

        // uint256 assetPrice = 
        //     IPriceOracleGetter(OracleStoreUtils.get(dataStore)).getPrice(position.underlyingAsset);

        uint256 assetPrice = OracleUtils.getPrice(dataStore, position.underlyingAsset);

        uint256 userCollateralUsd;
        uint256 userDebtUsd;

        if (position.hasCollateral){
            address poolToken = PoolStoreUtils.getPoolToken(dataStore, position.underlyingAsset);
            userCollateralUsd = IPoolToken(poolToken).balanceOfCollateral(position.account).rayMul(assetPrice);
        }

        if (position.hasDebt){
            address debtToken = PoolStoreUtils.getDebtToken(dataStore, position.underlyingAsset);
            userDebtUsd = IDebtToken(debtToken).balanceOf(position.account).rayMul(assetPrice);               
        }
        return (userCollateralUsd, userDebtUsd);
    }

    function validateEnabledPosition(Position.Props memory postion) internal pure {
        if (postion.account == address(0)) {
            revert Errors.EmptyPosition();
        }

    }

    function validateHealthFactor(
        address account,
        address dataStore,
        address underlyingAsset,
        uint256 amount
    ) internal view {

        (   uint256 userTotalCollateralUsd,
            uint256 userTotalDebtUsd
        ) = PositionUtils.calculateUserTotalCollateralAndDebt(account, dataStore);
        Printer.log("userTotalCollateralUsd",  userTotalCollateralUsd);
        Printer.log("userTotalDebtUsd",  userTotalDebtUsd);

        if (userTotalCollateralUsd == 0) { 
            revert Errors.CollateralBalanceIsZero();
        }

        uint256 amountUsd = OracleUtils.getPrice(dataStore, underlyingAsset)
                                            .rayMul(amount);

        Printer.log("amount",  amount);
        Printer.log("amountUsd",   amountUsd);

        uint256 healthFactor = 
            userTotalCollateralUsd.rayDiv(userTotalDebtUsd + amountUsd);
        uint256 healthFactorCollateralRateThreshold =
            ConfigStoreUtils.getHealthFactorCollateralRateThreshold(dataStore, underlyingAsset);

        Printer.log("healthFactor", healthFactor );
        Printer.log("healthFactorCollateralRateThreshold", healthFactorCollateralRateThreshold);

        if (healthFactor < healthFactorCollateralRateThreshold) {
            revert Errors.CollateralCanNotCover(
                userTotalCollateralUsd, 
                userTotalDebtUsd, 
                amountUsd,
                healthFactorCollateralRateThreshold
            );
        }

    }

    function maxAmountToRedeem(
        address account,
        address dataStore,
        address underlyingAsset,
        uint256 collateralAmount
    ) internal view returns (uint256) {

        if (collateralAmount == 0) {
            return 0;
        }

        (   uint256 userTotalCollateralUsd,
            uint256 userTotalDebtUsd
        ) = PositionUtils.calculateUserTotalCollateralAndDebt(account, dataStore);
        Printer.log("userTotalCollateralUsd",  userTotalCollateralUsd);
        Printer.log("userTotalDebtUsd",  userTotalDebtUsd);

        if (userTotalCollateralUsd == 0) { 
            revert Errors.CollateralBalanceIsZero();
        }

        uint256 price = OracleUtils.getPrice(dataStore, underlyingAsset);
        uint256 collateralAmountUsd = price.rayMul(collateralAmount);

        uint256 multiplierFactor = ConfigStoreUtils.getDebtMultiplierFactorForRedeem(dataStore);
        uint256 mulDebtUsd = userTotalDebtUsd.rayMul(multiplierFactor);
        if (userTotalCollateralUsd < mulDebtUsd) {
            return 0;
        }
        uint256 collteralSubMulDebt = (userTotalCollateralUsd - mulDebtUsd).rayDiv(price);

        Printer.log("collateralAmount",  collateralAmount);
        Printer.log("multiplierFactor",   multiplierFactor);
        Printer.log("collteralSubMulDebt",   collteralSubMulDebt);

        if (collteralSubMulDebt > collateralAmount) {
            return collateralAmount;
        }

        return collteralSubMulDebt;
    }

    function UpdateEntryLongPrice(
      Position.Props memory position,
      uint256 price,
      uint256 amount
    ) internal {

        if (position.positionType == Position.PositionTypeNone) {
            revert Errors.UsdDoNotHaveLongOperation();
        }

        if (position.positionType == Position.PositionTypeLong) {
            uint256 totalValue = position.entryLongPrice.rayMul(position.accLongAmount) +
                                 price.rayMul(amount);
            position.accLongAmount += amount;
            position.entryLongPrice = totalValue.rayDiv(position.accLongAmount);
        }

        if (position.positionType == Position.PositionTypeShort) {
            if (position.accLongAmount - amount > 0){
                position.accLongAmount -= amount;
            } else {
                position.positionType = Position.PositionTypeLong;
                position.accLongAmount = amount;
                position.entryLongPrice = price;
            }
        }

    }

    function UpdateEntryShortPrice(
      Position.Props memory position,
      uint256 price,
      uint256 amount
    ) internal {

        if (position.positionType == Position.PositionTypeNone) {
            revert Errors.UsdDoNotHaveShortOperation();
        }

        if (position.positionType == Position.PositionTypeShort) {
            uint256 totalValue = position.entryLongPrice.rayMul(position.accShortAmount) +
                                 price.rayMul(amount);
            position.accShortAmount += amount;
            position.entryShortPrice = totalValue.rayDiv(position.accShortAmount);
        }

        if (position.positionType == Position.PositionTypeShort) {
            if (position.accShortAmount - amount > 0){
                position.accShortAmount -= amount;
            } else {
                position.positionType = Position.PositionTypeShort;
                position.accShortAmount = amount;
                position.entryShortPrice = price;
            }
        }

    }


}