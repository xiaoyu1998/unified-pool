// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../role/RoleModule.sol";
import "../utils/GlobalReentrancyGuard.sol";
import "./ISupplyHandler.sol";
import "../supply/SupplyUtils.sol";

// @title SupplyHandler
// @dev Contract to handle execution of supply
contract SupplyHandler is ISupplyHandler, GlobalReentrancyGuard, RoleModule {
    EventEmitter public immutable eventEmitter;

    constructor(
        RoleStore _roleStore,
        DataStore _dataStore,
        EventEmitter _eventEmitter
    ) RoleModule(_roleStore) GlobalReentrancyGuard(_dataStore) {
        eventEmitter = _eventEmitter;
    }

    // @dev executes a supply
    // @param supplyParams SupplyUtils.SupplyParams
    function executeSupply(
        address account,
        SupplyUtils.SupplyParams calldata supplyParams
    ) external globalNonReentrant onlyController{

        SupplyUtils.ExecuteSupplyParams memory params = SupplyUtils.ExecuteSupplyParams(
           address(dataStore),
           address(eventEmitter),
           supplyParams.underlyingAsset,      
           supplyParams.to
        );

        return SupplyUtils.executeSupply(account, params);
    }

}
