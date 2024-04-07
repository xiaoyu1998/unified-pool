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
        DataStore dataStore
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
        DataStore dataStore,
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
        DataStore dataStore,
        address underlyingAsset,
        uint256 amount
    ) internal view returns (uint256, uint256) {

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


}