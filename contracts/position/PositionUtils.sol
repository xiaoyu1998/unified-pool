// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../data/DataStore.sol";
import "../error/Errors.sol";

import "../pool/Pool.sol";
import "../pool/PoolStoreUtils.sol";
import "../pool/IPoolToken.sol";
import "../pool/IDebtToken.sol";

import "./Position.sol";
import "./PositionStoreUtils.sol";

import "../oracle/IPriceOracleGetter.sol";
import "../oracle/OracleStoreUtils.sol";

// @title PositionUtils
// @dev Library for Position functions
library PositionUtils {

    using Position for Position.Props;
    using Pool for Pool.Props;
    
    //TODO:should change to multi-position
    function getPositionKey(address account) internal pure returns (bytes32) {
        bytes32 key = keccak256(abi.encode(account));
        return key;
    }

    struct calculateUserTotalCollateralAndDebtVars {
        uint256 i;
        uint256 assetPrice;
        uint256 userTotalCollateralInUsd;
        uint256 userTotalDebtInUsd;
    }

    function calculateUserTotalCollateralAndDebt(
        address account,
        DataStore dataStore,
        Position.Props memory position
    ) internal view returns (uint256, uint256) {

       calculateUserTotalCollateralAndDebtVars memory vars;
       uint256 poolCount = PoolStoreUtils.getPoolCount(dataStore);
       while (vars.i < poolCount) {
            if (!position.isUsingAsCollateralOrBorrowing(vars.i)){
                unchecked {
                  ++vars.i;
                }
                continue;               
            }

            bytes32 poolKey = PoolStoreUtils.getPoolKeyFromId(dataStore, vars.i);
            Pool.Props memory pool = PoolStoreUtils.get(dataStore, poolKey);

            vars.assetPrice = IPriceOracleGetter(OracleStoreUtils.get(dataStore)).getPrice(pool.underlyingAsset());

            if (position.isUsingAsCollateral(vars.i)){
                 vars.userTotalCollateralInUsd +=
                 IPoolToken(pool.poolToken()).balanceOfCollateral(account) * vars.assetPrice;
            }

            if (position.isBorrowing(vars.i)){
                 vars.userTotalDebtInUsd +=
                 IDebtToken(pool.debtToken()).balanceOf(account) * vars.assetPrice;  
                 //TODO: should assign pool to avoid reload               
            }

            unchecked {
                ++vars.i;
            }            
       }

       return (vars.userTotalCollateralInUsd, vars.userTotalDebtInUsd);
    }

    function calculateUserTotalCollateralAndDebt(
        address account,
        DataStore dataStore
    ) internal view returns (uint256, uint256) {
        Position.Props memory position  = PositionStoreUtils.get(params.dataStore, account);
        PositionUtils.validateEnabledPosition(position);
        return calculateUserTotalCollateralAndDebt(account, dataStore, position);
    }

    function validateEnabledPosition(Position.Props memory postion) internal view {
        if (postion.account() == address(0)) {
            revert Errors.EmptyPosition();
        }

    }

    // function getUserDebtInOnePool(
    //     address account,
    //     DataStore dataStore,
    //     Pool.Props memory pool 
    // ) internal pure returns (uint256, uint256, uint256) {


    // }




}