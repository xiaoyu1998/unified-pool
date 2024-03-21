// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../role/RoleModule.sol";
import "../utils/GlobalReentrancyGuard.sol";
import "./IWithdrawHandler.sol";
import "../withdraw/WithdrawUtils.sol";

// @title WithdrawHandler
// @dev Contract to handle execution of withdraw
contract WithdrawHandler is IWithdrawHandler, GlobalReentrancyGuard, RoleModule {

    constructor(
        RoleStore _roleStore,
        DataStore _dataStore
    ) RoleModule(_roleStore) GlobalReentrancyGuard(_dataStore) {

    }

    // @dev executes a withdraw
    // @param withdrawParams WithdrawUtils.WithdrawParams
    function executeWithdraw(
        address account,
        WithdrawUtils.WithdrawParams calldata withdrawParams
    ) external nonReentrant returns (bytes32){

        WithdrawUtils.ExecuteWithdrawParams memory params = WithdrawUtils.ExecuteWithdrawParams{
           dataStore,
           withdrawParams.underlyingAsset;        
           //withdrawParams.asset,
           withdrawParams.amount,
           withdrawParams.to
        };

        return WithdrawUtils.executeWithdraw(account, params);
    }

}
