// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../role/RoleModule.sol";
import "../utils/GlobalReentrancyGuard.sol";
import "./IDepositHandler.sol";
import "../deposit/ExecuteDepositUtils.sol";

// @title DepositHandler
// @dev Contract to handle execution of deposits
contract DepositHandler is IDepositHandler, GlobalReentrancyGuard, RoleModule {

    constructor(
        RoleStore _roleStore,
        DataStore _dataStore,
    ) RoleModule(_roleStore) GlobalReentrancyGuard(_dataStore) {

    }

    // @dev executes a deposit
    // @param depositParams DepositUtils.DepositParams
    function executeDeposit(
        address account,
        ExecuteDepositUtils.DepositParams calldata depositParams
    ) external nonReentrant returns (bytes32){

        ExecuteDepositUtils.ExecuteDepositParams memory params = ExecuteDepositUtils.ExecuteDepositParams{
           dataStore,
           depositParams.poolTokenAddress;        
           depositParams.asset,
           //depositParams.amount,
           depositParams.receiver
        };

        return ExecuteDepositUtils.executeDeposit(account, params);
    }

}
