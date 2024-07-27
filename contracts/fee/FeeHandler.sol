// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../data/DataStore.sol";
import "../role/RoleModule.sol";
import "../event/EventEmitter.sol";
import "../fee/FeeUtils.sol";
import "../fee/FeeStoreUtils.sol";

// @title FeeHandler
contract FeeHandler is ReentrancyGuard, RoleModule {
    DataStore public immutable dataStore;
    EventEmitter public immutable eventEmitter;

    constructor(
        RoleStore _roleStore,
        DataStore _dataStore,
        EventEmitter _eventEmitter
    ) RoleModule(_roleStore) {
        dataStore = _dataStore;
        eventEmitter = _eventEmitter;
    }

    // @dev claim fees from the specified pools
    // @param pools the pools to claim fees from
    function claimFees(
        address[] memory underlyingAssets
    ) external nonReentrant onlyFeeKeeper {
        if (underlyingAssets.length == 0) {
            revert Errors.EmptyUnderlyingAsset();
        }

        address treasury = FeeStoreUtils.getTreasury(address(dataStore));

        for (uint256 i; i < underlyingAssets.length; i++) {
            FeeUtils.claimFees(
                address(dataStore),
                address(eventEmitter),
                underlyingAssets[i],
                treasury
            );
        }
    }
}
