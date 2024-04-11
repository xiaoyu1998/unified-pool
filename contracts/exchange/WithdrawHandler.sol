// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../role/RoleModule.sol";
import "../utils/GlobalReentrancyGuard.sol";
import "./IWithdrawHandler.sol";
import "../withdraw/WithdrawUtils.sol";

// @title WithdrawHandler
// @dev Contract to handle execution of withdraw
contract WithdrawHandler is IWithdrawHandler, GlobalReentrancyGuard, RoleModule {
    EventEmitter public immutable eventEmitter;

    constructor(
        RoleStore _roleStore,
        DataStore _dataStore,
        EventEmitter _eventEmitter
    ) RoleModule(_roleStore) GlobalReentrancyGuard(_dataStore) {
        eventEmitter = _eventEmitter;
    }

    // @dev executes a withdraw
    // @param withdrawParams WithdrawUtils.WithdrawParams
    function executeWithdraw(
        address account,
        WithdrawUtils.WithdrawParams calldata withdrawParams
    ) external globalNonReentrant {

        WithdrawUtils.ExecuteWithdrawParams memory params = WithdrawUtils.ExecuteWithdrawParams(
           address(dataStore),
           address(eventEmitter),
           withdrawParams.underlyingAsset,     
           withdrawParams.amount,
           withdrawParams.to
        );

        return WithdrawUtils.executeWithdraw(account, params);
    }

}
