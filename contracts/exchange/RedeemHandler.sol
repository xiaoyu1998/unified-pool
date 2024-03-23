// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../role/RoleModule.sol";
import "../utils/GlobalReentrancyGuard.sol";
import "./IRedeemHandler.sol";
import "../redeem/RedeemUtils.sol";

// @title RedeemHandler
// @dev Contract to handle execution of redeem
contract RedeemHandler is IRedeemHandler, GlobalReentrancyGuard, RoleModule {

    constructor(
        RoleStore _roleStore,
        DataStore _dataStore
    ) RoleModule(_roleStore) GlobalReentrancyGuard(_dataStore) {

    }

    // @dev executes a redeem
    // @param redeemParams RedeemUtils.RedeemParams
    function executeRedeem(
        address account,
        RedeemUtils.RedeemParams calldata redeemParams
    ) external globalNonReentrant {

        RedeemUtils.ExecuteRedeemParams memory params = RedeemUtils.ExecuteRedeemParams(
           dataStore,
           redeemParams.underlyingAsset,       
           redeemParams.amount,
           redeemParams.to
        );

        return RedeemUtils.executeRedeem(account, params);
    }

}
