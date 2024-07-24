// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../role/RoleModule.sol";
import "../utils/GlobalReentrancyGuard.sol";
import "../event/EventEmitter.sol";
import "../liquidation/LiquidationUtils.sol";
import "./ILiquidationHandler.sol";

// @title LiquidationHandler
// @dev Contract to handle execution of liquidation
contract LiquidationHandler is ILiquidationHandler, GlobalReentrancyGuard, RoleModule {
    EventEmitter public immutable eventEmitter;

    constructor(
        RoleStore _roleStore,
        DataStore _dataStore,
        EventEmitter _eventEmitter
    ) RoleModule(_roleStore) GlobalReentrancyGuard(_dataStore) {
        eventEmitter = _eventEmitter;
    }

    // @dev executes a liquidation
    // @param liquidationParams LiquidationUtils.LiquidationParams
    function executeLiquidation(
        address liquidator,
        LiquidationUtils.LiquidationParams calldata liquidationParams
    ) external globalNonReentrant onlyController{

        LiquidationUtils.ExecuteLiquidationParams memory params = LiquidationUtils.ExecuteLiquidationParams(
           address(dataStore),
           address(eventEmitter),
           liquidationParams.account
        );

        return LiquidationUtils.executeLiquidation(liquidator, params);
    }

}
