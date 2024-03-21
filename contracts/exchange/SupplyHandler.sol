// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../role/RoleModule.sol";
import "../utils/GlobalReentrancyGuard.sol";
import "./ISupplyHandler.sol";
import "../supply/SupplyUtils.sol";

// @title SupplyHandler
// @dev Contract to handle execution of supplys
contract SupplyHandler is ISupplyHandler, GlobalReentrancyGuard, RoleModule {

    constructor(
        RoleStore _roleStore,
        DataStore _dataStore
    ) RoleModule(_roleStore) GlobalReentrancyGuard(_dataStore) {

    }

    // @dev executes a supply
    // @param supplyParams SupplyUtils.SupplyParams
    function executeSupply(
        address account,
        SupplyUtils.SupplyParams calldata supplyParams
    ) external nonReentrant returns (bytes32){

        SupplyUtils.ExecuteSupplyParams memory params = SupplyUtils.ExecuteSupplyParams{
           dataStore,
           supplyParams.underlyingAsset,      
           supplyParams.receiver
        };

        return SupplyUtils.executeSupply(account, params);
    }

}
