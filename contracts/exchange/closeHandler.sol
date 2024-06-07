// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import "../role/RoleModule.sol";
import "../utils/GlobalReentrancyGuard.sol";
import "./ICloseHandler.sol";
import "../close/CloseUtils.sol";

// @title CloseHandler
// @dev Contract to handle execution of close
contract CloseHandler is ICloseHandler, GlobalReentrancyGuard, RoleModule {
    EventEmitter public immutable eventEmitter;

    constructor(
        RoleStore _roleStore,
        DataStore _dataStore,
        EventEmitter _eventEmitter
    ) RoleModule(_roleStore) GlobalReentrancyGuard(_dataStore) {
        eventEmitter = _eventEmitter;
    }

    // // @dev executes a close
    // // @param closeParams CloseUtils.CloseParams
    function executeClose(
        address account,
        CloseUtils.CloseParams calldata closeParams
    ) external globalNonReentrant onlyController{

        CloseUtils.ExecuteCloseParams memory params = CloseUtils.ExecuteCloseParams(
           address(dataStore),
           address(eventEmitter),
           closeParams.underlyingAssetUsd
        );

        return CloseUtils.executeClose(account, params);
    }

    // @dev executes a close position
    // @param closeParams ClosePositionUtils.ClosePositionParams
    function executeClosePosition(
        address account,
        CloseUtils.ClosePositionParams calldata closeParams
    ) external globalNonReentrant {

        CloseUtils.ExecuteClosePositionParams memory params = CloseUtils.ExecuteClosePositionParams(
           address(dataStore),
           address(eventEmitter),
           closeParams.underlyingAsset,
           closeParams.underlyingAssetUsd
        );

        return CloseUtils.executeClosePosition(account, params);
    }

}
