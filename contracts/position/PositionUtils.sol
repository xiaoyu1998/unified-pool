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

import "../oracle/IPriceOracleGetter.sol";
import "../oracle/OracleStoreUtils.sol";

// @title PositionUtils
// @dev Library for Position functions
library PositionUtils {

    using Position for Position.Props;
    using Pool for Pool.Props;

    // struct calculateUserTotalCollateralAndDebtVars {
    //     uint256 i;
    //     uint256 userTotalCollateralUsd;
    //     uint256 userTotalDebtUsd;
    // }

    function calculateUserTotalCollateralAndDebt(
        address account,
        DataStore dataStore
    ) internal view returns (uint256, uint256) {
        uint256 positionsCount = PositionStoreUtils.getAccountPositionCount(dataStore, account);
        if(positionsCount == 0) return (0, 0);

        Position.Props memory positions[] = 
            PositionStoreUtils.getAccountPositionCount(dataStore, account, 0, positionsCount);
        calculateUserTotalCollateralAndDebtVars memory vars;
        uint256 userTotalCollateralUsd;
        uint256 userTotalDebtUsd;        
        for (uint256 i = 0; i < positionsCount; i++) {

            (uint256 userCollateralUsd, uint256 userDebtUsd) = 
                calculateUserCollateralAndDebtInPosition(datatore, position[i]);
            userTotalCollateralUsd += userCollateralUsd;
            userTotalDebtUsd += userDebtUsd;            
        }

        return (userTotalCollateralUsd, userTotalDebtUsd);

    }

    function calculateUserCollateralAndDebtInPosition(
        DataStore dataStore,
        Position.Props memory position
    ) internal view returns (uint256, uint256) {

        // Pool.Props memory pool = PoolStoreUtils.get(dataStore, position.underlyingAsset);

        uint256 assetPrice = 
            IPriceOracleGetter(OracleStoreUtils.get(dataStore)).getPrice(position.underlyingAsset);
        uint256 userCollateralUsd;
        uint256 userDebtUsd;

        if (position.hasCollateral){
            address poolToken = PoolStoreUtils.getPoolToken(dataStore, position.underlyingAsset);
            userCollateralUsd = IPoolToken(poolToken).balanceOfCollateral(position.account) * assetPrice;
        }

        if (position.hasDebt){
            address debtToken = PoolStoreUtils.getDebtToken(dataStore, position.underlyingAsset);
            userDebtUsd = IDebtToken(debtToken).balanceOf(position.account) * assetPrice;               
        }
        return (userCollateralUsd, userDebtUsd);
    }

    function validateEnabledPosition(Position.Props memory postion) internal pure {
        if (postion.account == address(0)) {
            revert Errors.EmptyPosition();
        }

    }


}