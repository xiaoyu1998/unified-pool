// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../role/RoleModule.sol";
import "../utils/GlobalReentrancyGuard.sol";
import "./IRedeemHandler.sol";
import "../redeem/RedeemUtils.sol";

// @title RedeemHandler
// @dev Contract to handle execution of redeem
contract RedeemHandler is IRedeemHandler, GlobalReentrancyGuard, RoleModule {
    EventEmitter public immutable eventEmitter;

    constructor(
        RoleStore _roleStore,
        DataStore _dataStore,
        EventEmitter _eventEmitter
    ) RoleModule(_roleStore) GlobalReentrancyGuard(_dataStore) {
        eventEmitter = _eventEmitter;
    }

    // @dev executes a redeem
    // @param redeemParams RedeemUtils.RedeemParams
    function executeRedeem(
        address account,
        RedeemUtils.RedeemParams calldata redeemParams
    ) external globalNonReentrant onlyController{
        //Printer.log("redeemParams.amount", redeemParams.amount); 
        RedeemUtils.ExecuteRedeemParams memory params = RedeemUtils.ExecuteRedeemParams(
           address(dataStore),
           address(eventEmitter),
           redeemParams.underlyingAsset,       
           redeemParams.amount,
           redeemParams.to
        );

        return RedeemUtils.executeRedeem(account, params);
    }

}
