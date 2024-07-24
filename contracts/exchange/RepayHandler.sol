// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../role/RoleModule.sol";
import "../utils/GlobalReentrancyGuard.sol";
import "../repay/RepayUtils.sol";
import "../event/EventEmitter.sol";
import "./IRepayHandler.sol";

// @title RepayHandler
// @dev Contract to handle execution of repay
contract RepayHandler is IRepayHandler, GlobalReentrancyGuard, RoleModule {
    EventEmitter public immutable eventEmitter;

    constructor(
        RoleStore _roleStore,
        DataStore _dataStore,
        EventEmitter _eventEmitter
    ) RoleModule(_roleStore) GlobalReentrancyGuard(_dataStore) {
        eventEmitter = _eventEmitter;
    }

    // @dev executes a repay
    // @param repayParams RepayUtils.RepayParams
    function executeRepay(
        address account,
        RepayUtils.RepayParams calldata repayParams
    ) external globalNonReentrant onlyController{

        RepayUtils.ExecuteRepayParams memory params = RepayUtils.ExecuteRepayParams(
            address(dataStore),
            address(eventEmitter),
            repayParams.underlyingAsset,   
            repayParams.amount  
        );

        return RepayUtils.executeRepay(account, params);
    }

}
