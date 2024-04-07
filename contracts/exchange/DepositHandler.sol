// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../role/RoleModule.sol";
import "../utils/GlobalReentrancyGuard.sol";
import "./IDepositHandler.sol";
import "../deposit/DepositUtils.sol";

// @title DepositHandler
// @dev Contract to handle execution of deposit
contract DepositHandler is IDepositHandler, GlobalReentrancyGuard, RoleModule {

    constructor(
        RoleStore _roleStore,
        DataStore _dataStore
    ) RoleModule(_roleStore) GlobalReentrancyGuard(_dataStore) {

    }

    // @dev executes a deposit
    // @param depositParams DepositUtils.DepositParams
    function executeDeposit(
        address account,
        DepositUtils.DepositParams calldata depositParams
    ) external globalNonReentrant {

        DepositUtils.ExecuteDepositParams memory params = DepositUtils.ExecuteDepositParams(
           address(dataStore),
           depositParams.underlyingAsset      
        );

        return DepositUtils.executeDeposit(account, params);
    }

}
