// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/Math.sol";
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
            position.positionType = Position.PositionTypeNone;
            position.hasCollateral = false;
            position.hasDebt = false;
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

    function getPositions(address account, address dataStore) internal view returns (Position.Props[] memory) {
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

    function calculateUserTotalCollateralAndDebt(
        address account,
        address dataStore
    ) internal view returns (uint256, uint256) {
        Printer.log("-------------------------calculateUserTotalCollateralAndDebt--------------------------");
        // Printer.log("account", account);
        Position.Props[] memory positions = PositionUtils.getPositions(account, dataStore);

        uint256 userTotalCollateralUsd;
        uint256 userTotalDebtUsd;        
        for (uint256 i = 0; i < positions.length; i++) {
            Position.Props memory position = positions[i];
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

    function getLiquidationHealthFactor(
        address account,
        address dataStore
    ) internal view returns(uint256, uint256, bool, uint256, uint256) {
        Printer.log("-------------------------getLiquidationHealthFactor--------------------------");
        (   uint256 userTotalCollateralUsd,
            uint256 userTotalDebtUsd
        ) = PositionUtils.calculateUserTotalCollateralAndDebt(account, dataStore);

        Printer.log("userTotalCollateralUsd", userTotalCollateralUsd);
        Printer.log("userTotalDebtUsd", userTotalDebtUsd);
        uint256 healthFactor;
        if (userTotalDebtUsd > 0 )
            healthFactor = userTotalCollateralUsd.rayDiv(userTotalDebtUsd);

        uint256 healthFactorLiquidationThreshold =
            ConfigStoreUtils.getHealthFactorLiquidationThreshold(dataStore);
        Printer.log("healthFactorLiquidationThreshold", healthFactorLiquidationThreshold);

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
        Printer.log("-------------------------validateLiquidationHealthFactor--------------------------");
        (   uint256 userTotalCollateralUsd,
            uint256 userTotalDebtUsd
        ) = PositionUtils.calculateUserTotalCollateralAndDebt(account, dataStore);
        Printer.log("userTotalCollateralUsd",  userTotalCollateralUsd);
        Printer.log("userTotalDebtUsd",  userTotalDebtUsd);

        if (userTotalCollateralUsd == 0) { 
            revert Errors.CollateralBalanceIsZero();
        }
        
        uint256 adjustAmount = Math.mulDiv(amount, WadRayMath.RAY, 10**decimals);//align to Ray
        uint256 amountUsd = OracleUtils.getPrice(dataStore, underlyingAsset)
                                            .rayMul(adjustAmount);
        Printer.log("amount",  amount);
        Printer.log("amountUsd",   amountUsd);

        uint256 healthFactor = 
            (userTotalCollateralUsd + amountUsd).rayDiv(userTotalDebtUsd + amountUsd);

        uint256 healthFactorLiquidationThreshold =
            ConfigStoreUtils.getHealthFactorLiquidationThreshold(dataStore);

        Printer.log("healthFactor", healthFactor );
        Printer.log("healthFactorLiquidationThreshold", healthFactorLiquidationThreshold);

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
        Printer.log("-------------------------validateCollateralRateHealthFactor--------------------------");
        uint256 healthFactor = 
            (collateralAmount + amount).rayDiv(debtAmount + amount);

        uint256 healthFactorCollateralRateThreshold =
            ConfigStoreUtils.getHealthFactorCollateralRateThreshold(dataStore, underlyingAsset);  

        Printer.log("collateralAmount", collateralAmount );
        Printer.log("debtAmount", debtAmount); 
        Printer.log("amount", amount); 
        Printer.log("healthFactor", healthFactor );
        Printer.log("healthFactorCollateralRateThreshold", healthFactorCollateralRateThreshold);      
        if (healthFactor < healthFactorCollateralRateThreshold) {
            revert Errors.HealthFactorLowerThanCollateralRateThreshold(
                healthFactor, 
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

        uint256 multiplierFactor = ConfigStoreUtils.getDebtMultiplierFactorForRedeem(dataStore);
        uint256 timesTotalDebtUsd = userTotalDebtUsd.rayMul(multiplierFactor);
        if (userTotalCollateralUsd < timesTotalDebtUsd) {
            return 0;
        }
        uint256 price = OracleUtils.getPrice(dataStore, underlyingAsset);
        uint256 totalAvailable = (userTotalCollateralUsd - timesTotalDebtUsd).rayDiv(price);

        Printer.log("collateralAmount",  collateralAmount);
        Printer.log("multiplierFactor",   multiplierFactor);
        Printer.log("totalAvailable",   totalAvailable);

        if (totalAvailable > collateralAmount) {
            return collateralAmount;
        }

        return totalAvailable;
    }

    function longPosition(
      Position.Props memory position,
      uint256 price,
      uint256 amount
    ) internal pure {
        //1st deposit/repay/swap after reset
        if (position.positionType == Position.PositionTypeNone) {
            //revert Errors.UsdDoNotHaveLongOperation();
            position.positionType = Position.PositionTypeLong;
            position.accLongAmount = amount;
            position.accLongAmount = price;

        }

        if (position.positionType == Position.PositionTypeLong) {
            position.accLongAmount += amount;
            if (price != 0){
                uint256 totalValue = position.entryLongPrice.rayMul(position.accLongAmount) +
                                     price.rayMul(amount);
                position.entryLongPrice = totalValue.rayDiv(position.accLongAmount);
            }
        }

        if (position.positionType == Position.PositionTypeShort) {
            if (position.accShortAmount - amount > 0){
                position.accShortAmount -= amount;
            } else {
                position.positionType = Position.PositionTypeLong;
                position.accLongAmount = amount - position.accShortAmount;
                position.accShortAmount = 0;
                position.entryShortPrice = 0;
                if (price != 0){//TODO:repay should close postion, no longer need price
                    position.entryLongPrice = price;
                }
            }
        }
    }

    function shortPosition(
      Position.Props memory position,
      uint256 price,
      uint256 amount
    ) internal pure {
        //1st borrow/redeem/swap after reset
        if (position.positionType == Position.PositionTypeNone) {
            //revert Errors.UsdDoNotHaveShortOperation();
            position.positionType = Position.PositionTypeShort;
            position.accShortAmount = amount;
            position.accShortAmount = price;
        }

        if (position.positionType == Position.PositionTypeShort) {
            position.accShortAmount += amount;
            if (price != 0){//
                uint256 totalValue = position.entryLongPrice.rayMul(position.accShortAmount) +
                                     price.rayMul(amount);
                position.entryShortPrice = totalValue.rayDiv(position.accShortAmount);
            }
        }

        if (position.positionType == Position.PositionTypeLong) {
            if (position.accLongAmount - amount > 0){
                position.accLongAmount -= amount;
            } else {
                position.positionType = Position.PositionTypeShort;
                position.accShortAmount = amount - position.accLongAmount;
                position.accLongAmount = 0;
                position.entryLongPrice = 0;
                if (price != 0){//TODO:redeem should close position, no longer need price
                    position.entryShortPrice = price;
                }
            }
        }
    }


}