// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../role/RoleModule.sol";
import "../utils/GlobalReentrancyGuard.sol";
import "./IRepayHandler.sol";
import "../repay/RepayUtils.sol";

// @title RepayHandler
// @dev Contract to handle execution of repay
contract RepayHandler is IRepayHandler, GlobalReentrancyGuard, RoleModule {

    constructor(
        RoleStore _roleStore,
        DataStore _dataStore
    ) RoleModule(_roleStore) GlobalReentrancyGuard(_dataStore) {

    }

    // @dev executes a repay
    // @param repayParams RepayUtils.RepayParams
    function executeRepay(
        address account,
        RepayUtils.RepayParams calldata repayParams
    ) external nonReentrant returns (bytes32){

        RepayUtils.ExecuteRepayParams memory params = RepayUtils.ExecuteRepayParams{
           dataStore,
           repayParams.poolTokenAddress;        
           // repayParams.asset,
           //repayParams.amount,
        };

        return RepayUtils.executeRepay(account, params);
    }

}
